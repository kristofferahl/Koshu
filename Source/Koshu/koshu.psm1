#------------------------------------------------------------
# Variables
#------------------------------------------------------------

$script:koshu		= @{}
$koshu.version		= '0.4.0'
$koshu.verbose		= $false

$psakeVersion		= '4.2.0.1'
$koshuDir			= $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "") -replace ".$"
$psakeDir			= ((Resolve-Path $koshuDir) | Split-Path -parent | Split-Path  -parent)

#------------------------------------------------------------
# Tasks
#------------------------------------------------------------

function Koshu-Build($buildFile=$(Read-Host "Build file: "), $target="Default", $psakeParameters=@{}) {
	Write-Host "Koshu - version " $koshu.version
	Write-Host "Copyright (c) 2012 Kristoffer Ahl"
	
	Assert ($buildFile -ne $null -and $buildFile -ne "") "No build file specified!"
	
	if ("$buildFile".EndsWith(".ps1") -eq $false) {
		$buildFile = "$buildFile.ps1"
	}
	
	$buildFile = try_find $buildFile
	Assert (test-path $buildFile) "Build file not found: $buildFile"
	
	Write-Host "Invoking psake with properties" ($psakeParameters | Out-String) "."
	Invoke-Psake $buildFile $target -properties $psakeParameters;

	if ($psake.build_success -eq $false) {
		if ($lastexitcode -ne 0) {
			Write-Host "Build failed! Exit code: $lastexitcode." -fore RED;
			exit $lastexitcode
		} else {
			Write-Host "Build failed!" -fore RED;
			exit 1
		}
	} else {
		exit 0
	}
}

function Koshu-Scaffold($template=$(Read-Host "Template: "), $projectName, $buildName='', $buildTarget, $rootDir='.\') {
	Assert ($template -ne $null -and $template -ne "") "No template name specified!"

	Write-Host "Scaffolding Koshu template" $template

	if ("$rootDir".EndsWith("\") -eq $true) {
		$rootDir = $rootDir -replace ".$"
	}
	
	$template			= $template.ToLower()
	$buildName			= $buildName.ToLower()
	$templateName		= ?: {$buildName -ne ''} {"$buildName-$template"} {"$template"} 
	$triggerName		= (?: {$buildTarget -ne $null} {"$templateName-$buildTarget"} {"$templateName"}).ToString().ToLower()
	$buildTarget		= (?: {$buildTarget -ne $null} {"$buildTarget"} {"default"}).ToString().ToLower()
	
	$koshuFileSource		= "$koshuDir\Templates\koshu.ps1"
	$koshuFileDestination	= "$rootDir\koshu.ps1"
	$packagesDir			= (Resolve-Path "$koshuDir\..\..") -replace [regex]::Escape((Resolve-Path $rootDir)), "."
	
	scaffold_koshufile $koshuFileSource $koshuFileDestination $koshu.version $packagesDir
	
	$templateFile = "$rootDir\$templateName.ps1"
	if (!(test-path $templateFile)) {
		(cat "$koshuDir\Templates\$template.ps1") | out-file $templateFile -encoding "Default" -force
		Write-Host "Created build template $templateFile"
	}
	
	$triggerFile = "$rootDir\$triggerName.cmd"
	if (!(test-path $triggerFile)) {
		(cat "$koshuDir\Templates\$template-trigger.cmd") -replace "buildFile.ps1","$templateName.ps1" -replace "TARGET",$buildTarget | out-file $triggerFile -encoding "Default" -force
		Write-Host "Created build trigger $triggerFile"
	}
}

#------------------------------------------------------------
# Includes
#------------------------------------------------------------

. "$koshuDir\koshu-functions.ps1"
. "$koshuDir\koshu-helpers.ps1"

#------------------------------------------------------------
# Filters
#------------------------------------------------------------

filter invoke_ternary([scriptblock]$decider, [scriptblock]$iftrue, [scriptblock]$iffalse) {
	if (&$decider) { &$iftrue } else { &$iffalse }
}

#------------------------------------------------------------
# Aliases
#------------------------------------------------------------

set-alias ?: invoke_ternary


#------------------------------------------------------------
# Setup
#------------------------------------------------------------

if ($Args.Length -gt 0) {
    $psakeDir = $Args[0] -as [string]
	Write-Host "Overriding psakeDir with argument $psakeDir"
}

nuget_install psake $psakeVersion $psakeDir
if(-not(Get-Module -name "psake")) {
	Import-Module "$psakeDir\psake.$psakeVersion\tools\psake.psm1"
}


#------------------------------------------------------------
# Export
#------------------------------------------------------------

export-modulemember -function Koshu-Build, Koshu-Scaffold
export-modulemember -function create_directory, delete_directory, delete_files, copy_files, copy_files_flatten, try_find
export-modulemember -function build_solution, pack_solution, nuget_install, exec_retry
export-modulemember -function invoke_ternary
export-modulemember -alias ?:
export-modulemember -variable koshu