#------------------------------------------------------------
# Variables
#------------------------------------------------------------

# TODO: Move variables into context object
# TODO: Set Koshu version and psake version from build script for Koshu
$script:koshu		= @{}
$koshu.version		= '0.5.1'
$koshu.verbose		= $false
$koshu.context		= new-object system.collections.stack # holds onto the current state of all variables

$psakeVersion		= '4.2.0.1'
$koshuDir			= $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "") -replace ".$"
$psakeDir			= ((Resolve-Path $koshuDir) | Split-Path -parent | Split-Path  -parent)

#------------------------------------------------------------
# Tasks
#------------------------------------------------------------

function Packages {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1,ValueFromPipeline=$True)]$packages
	)
	$koshu.context.peek().packages += $packages
}

function Config {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1,ValueFromPipeline=$True)]$config
	)
	$koshu.context.peek().config += $config
}

function Koshu-Build([string]$buildFile=$(Read-Host "Build file: "), [string[]]$tasks=@("default"), [hashtable]$properties=@{}) {
	Write-Host "Koshu - version " $koshu.version
	Write-Host "Copyright (c) 2012 Kristoffer Ahl"
	
	Assert ($buildFile -ne $null -and $buildFile -ne "") "No build file specified!"
	
	if ("$buildFile".EndsWith(".ps1") -eq $false) {
		$buildFile = "$buildFile.ps1"
	}
	
	$buildFile = find_up $buildFile . -file
	Assert (test-path $buildFile) "Build file not found: $buildFile"

	$koshu.context.push(@{
		"packages" = [ordered]@{};
		"config" = [ordered]@{}
		"initParameters" = @{
			"rootDir" = ($buildFile | split-path -parent)
			"buildFile" = $buildFile
			"tasks" = $tasks
			"properties" = $properties
		}
	})

	Write-Host "Invoking psake with properties:" ($properties | Out-String)
	Invoke-Psake $buildFile -taskList $tasks -properties $properties -initialization {
		$context = $koshu.context.peek()
		if ($context.packages.count -gt 0) {
			Write-Host "Installing Koshu packages" -fore yellow
			$context.packages.GetEnumerator() | % {
				$packageConfig = $context.config.get_item($_.key)
				if ($packageConfig -eq $null) {
					$packageConfig = @{}
				}
				Koshu-InstallPackage -key $_.key -value $_.value -initParameters $context.initParameters -config $packageConfig
			}
		}
	};

	if ($psake.build_success -eq $false) {
		if ($lastexitcode -ne 0) {
			Write-Host "Build failed! Exit code: $lastexitcode." -fore red;
			exit $lastexitcode
		} else {
			Write-Host "Build failed!" -fore RED;
			exit 1
		}
	} else {
		exit 0
	}
}

function Koshu-Scaffold($template=$(Read-Host "Template: "), $productName='Product.Name', $buildName='', $buildTarget, $rootDir='.\') {
	Assert ($template -ne $null -and $template -ne "") "No template name specified!"

	Write-Host "Scaffolding Koshu template" $template

	if ("$rootDir".EndsWith("\") -eq $true) {
		$rootDir = $rootDir -replace ".$"
	}
	
	if ($productName -eq 'Product.Name') {
		try {
			$productName = [IO.Path]::GetFilenameWithoutExtension((Split-Path -Path $dte.Solution.FullName -Leaf))
		} catch {}
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
		(get-content "$koshuDir\Templates\$template.ps1") -replace "Product.Name", $productName | out-file $templateFile -encoding "Default" -force
		Write-Host "Created build template $templateFile"
	}
	
	$triggerFile = "$rootDir\$triggerName.cmd"
	if (!(test-path $triggerFile)) {
		(get-content "$koshuDir\Templates\$template-trigger.cmd") -replace "buildFile.ps1","$templateName.ps1" -replace "TARGET",$buildTarget | out-file $triggerFile -encoding "Default" -force
		Write-Host "Created build trigger $triggerFile"
	}
}

function Koshu-InstallPackage([string]$key, [string]$value, [hashtable]$initParameters, [hashtable]$config) {
	# PACKAGE: PSGet installer package (To enable usage of PSGet packages in the builds)
	# PACKAGE: File system watcher package (Allows for watching a directory and run powershell code when it changes)
	# PACKAGE: ...

	# TODO: Rename Koshu-InstallPackage to Koshu-InitPackage. Kosku-InstallPackage should simply install and nothing else. Koshu-InitPackage should call Koshu-Install and then call init.ps1.
	# TODO: Rename the repository for the package plugin template??? Koshu.PluginTemplate???
	# TODO: Define where koshu packages should be installed
	# TODO: Add support for nuget package
	# TODO: git reset --hard after checking out sha/tag???
	# TODO: Verify support for the NPM style urls (ssh dit not work previously but http, https and git dif)
		# git://github.com/user/project.git#commit-ish
		# git+ssh://user@hostname:project.git#commit-ish
		# git+http://user@hostname/project/blah.git#commit-ish
		# git+https://user@hostname/project/blah.git#commit-ish

	$name = $key
	$destinationDir = "$koshuDir\..\..\$name"

	$isGitPackage = ($value -like "git+*" -or $value -like "git:*")
	if ($isGitPackage) {
		$repository = $value
		install_git_package $repository $destinationDir "Installing package $name from git ($repository)" 
	} else {
		$version = $value
		install_nuget_package $name $version $destinationDir "Installing package $name.$version from nuget" 
	}
	
	$initFile = "$destinationDir\tools\init.ps1"
	$hasManifest = $false
	if ((test-path "$destinationDir\koshu.manifest") -eq $true) {
		$hasManifest = $true
		$manifestPath = get-content "$destinationDir\koshu.manifest"
		$initFile = "$destinationDir\$manifestPath\init.ps1"
	}
	
	if ((test-path $initFile) -eq $false) {
		if ($hasManifest -eq $true) {
			throw "init.ps1 could not be found ($initFile). The path in koshu.manifest is incorrect!"
		} else {
			throw "init.ps1 could not be found ($initFile). Create a koshu.manifest file containing the path to the directory where init.ps1 is located."
		}
	}
	
	write-host "  Initializing package $name"
	. $initFile -parameters $initParameters -config $config
}

function install_git_package($repository, $destinationDir, $message) {
	write-host $message

	$value = $null
	
	$repository = $repository -replace 'git\+', ''

	$pattern = '(?i)#(.*)'
	$result = [Regex]::Matches($repository, $pattern)
	if ($result.success -eq $true) {
		$value = $result.groups[1].value.tostring()
		$repository = $repository -replace $result.value, ''
	}

	if (test-path $destinationDir) {
		remove-item "$destinationDir" -recurse -force
	}
	new-item $destinationDir -type directory | out-null

	invoke-expression "git clone $repository $destinationDir --quiet"

	if ($value -ne $null) {
		set-location $destinationDir
		write-host "  Checking out $value"
		invoke-expression "git checkout $value --quiet"
	}

	remove-item "$destinationDir\.git" -recurse -force
}

function install_nuget_package($repository, $destinationDir, $message) {
	write-host $message
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

nuget_exe install psake -version $psakeVersion -outputdirectory $psakeDir
if(-not(Get-Module -name "psake")) {
	Import-Module "$psakeDir\psake.$psakeVersion\tools\psake.psm1"
}

#------------------------------------------------------------
# Export
#------------------------------------------------------------

export-modulemember -function Packages, Config, Koshu-Build, Koshu-Scaffold, Koshu-InstallPackage
export-modulemember -function create_directory, delete_directory, delete_files, copy_files, copy_files_flatten, find_down, find_up
export-modulemember -function build_solution, pack_solution
export-modulemember -function nuget_exe, run, exec_retry
export-modulemember -function invoke_ternary
export-modulemember -alias ?:
export-modulemember -variable koshu