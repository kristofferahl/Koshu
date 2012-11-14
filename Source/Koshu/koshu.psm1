#------------------------------------------------------------
# Variables
#------------------------------------------------------------

$script:koshu		= @{}
$koshu.version		= '0.1.0'
$koshu.verbose		= $false

$psakeVersion		= '4.2.0.1'
$koshuDir			= $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "") -replace ".$"
$psakeDir			= ((Resolve-Path $koshuDir) | Split-Path -parent | Split-Path  -parent)


#------------------------------------------------------------
# Tasks
#------------------------------------------------------------

function Koshu-Build($buildFile, $target="Default", $psakeParameters=@{}) {
	Write-Host "Koshu - version " $koshu.version
	Write-Host "Copyright (c) 2012 Kristoffer Ahl"
	
	Assert ($buildFile -ne $null) "No build file specified!"
	
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

function Koshu-Scaffold($template, $projectName, $rootDir='.\', $buildTarget) {
	Write-Host "Scaffolding Koshu template" $template "for" $projectName
	
	$template			= $template.ToLower()
	$projectName		= $projectName.ToLower()
	$templateName		= "$projectName-$template"
	$triggerName		= $templateName
	
	if ("$rootDir".EndsWith("\") -eq $true) {
		$rootDir = $rootDir -replace ".$"
	}
	$toolsDirRel		= $koshuDir -replace [regex]::Escape($rootDir), "."
	
	if ($buildTarget -eq $null) {
		$buildTarget = 'default'
	} else {
		$triggerName = "$templateName-$buildTarget".ToLower()
	}
	$buildTarget = $buildTarget.ToLower()
	
	$koshuFile = "$rootDir\koshu.cmd"
	if (!(test-path $koshuFile)) {
		(cat "$koshuDir\koshu.cmd") -replace "init.ps1","$toolsDirRel\init.ps1" -replace "TARGET","Release" | out-file $koshuFile -encoding "Default" -force
		Write-Host "Created koshu trigger $koshuFile"
	}
	
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
# Functions
#------------------------------------------------------------

function create_directory($directoryName) {
	if (!(test-path $directoryName -pathtype container)) {
		New-Item $directoryName -Type directory -Force -Verbose:$koshu.verbose
	}
}

function delete_directory($directoryName) {
	if (test-path $directoryName -pathtype container) {
		Remove-Item -Recurse -Force $directoryName -Verbose:$koshu.verbose
	}
}

function delete_files($source, $include=@("*"), $exclude=@()) {
	if (test-path $source -pathtype container) {
		Write-Host "Removing files in '$source'. Include '$include'. Exclude '$exclude'"
		Remove-Item -Recurse -Force "$source\*" -Include $include -Exclude $exclude -Verbose:$koshu.verbose
	}
}

function copy_files($source, $destination, $include=@("*.*"), $exclude=@()) {
	if (test-path $source) {
		$copiedFiles = 0
		Write-Host "Copying '$source' to '$destination'. Include '$include'. Exclude '$exclude'"

		New-Item -ItemType Directory -Path $destination -Force | Out-Null

		Get-ChildItem $source -Recurse -Include $include -Exclude $exclude | % {
			$fullSourcePath = (Resolve-Path $source)
			$fullDestinationPath = (Resolve-Path $destination)
			$itemPath = $_.FullName -replace [regex]::Escape($fullSourcePath),[regex]::Escape($fullDestinationPath)

			if ($koshu.verbose -eq $true) { Write-Host "Copying '$_' to '$itemPath'." }

			if (!($_.PSIsContainer)) {
				New-Item -ItemType File -Path $itemPath -Force | Out-Null
			}
			Copy-Item -Force -Path $_ -Destination $itemPath | Out-Null

			$copiedFiles++
		}

		Write-Host "Copied $copiedFiles $(if ($copiedFiles -eq 1) { "item" } else { "items" })."
	}
}

function copy_files_flatten($source, $destination, $filter) {
	create_directory $destination
	foreach($f in $filter.split(",")) {
		Get-ChildeItem $source -filter $f.trim() -r | Copy-Item -dest $destination
	}
}

function try_find($path, $maxLevelsUp=3) {
	if (!(test-path $path)) {
		$levelsUp = 0
		do {
			Write-Host "Path $path not found. Trying one level up."
			$path = "..\$path"
			$levelsUp++
		} while (!(test-path $path) -and $levelsUp -lt $maxLevelsUp)	
	}
	return $path
}

function build_solution($solutionName) {
	Assert (test-path $solutionName) "$solutionName could not be found"
	$buildVerbosity = 'quiet'
	if ($koshu.verbose -eq $true) {
		$buildVerbosity = 'minial'
	}
	exec {
		msbuild $solutionName /target:Rebuild /property:Configuration=$configuration /verbosity:$buildVerbosity
	}
}

function pack_solution($solutionName, $destination, $packageName) {
	Assert (test-path $solutionName) "$solutionName could not be found"
	
	create_directory $destination

	$packageRoot	= (Resolve-Path $destination)
	$packageDir		= "$packageRoot\$packageName"

	create_directory $packageDir

	$buildVerbosity = 'quiet'
	if ($koshu.verbose -eq $true) {
		$buildVerbosity = 'minial'
	}

	exec {
		msbuild $solutionName `
			/target:Publish `
			/property:Configuration=$configuration `
			/property:_PackageTempDir=$packageDir `
			/verbosity:$buildVerbosity
	}
}

function nuget_install($package, $version, $target='.\') {
	try {
		if ($version -ne $null) {
			nuget install $package -Version $version -OutputDirectory $target
		} else {
			nuget install $package -OutputDirectory $target
		}
	} catch [System.Management.Automation.CommandNotFoundException] {
		throw 'Nuget.exe is not in your path! Add it to your environment variables.'
	}
}

function exec_retry([scriptblock]$command, [string]$commandName, [int]$retries = 3) {
	$currentRetry = 0
	$success = $false

	do {
		try {
			& $command;
			$success = $true
			Write-Host "Successfully executed [$commandName] command. Number of retries: $currentRetry."
		} catch [System.Exception] {
			Write-Host "Exception occurred while trying to execute [$commandName] command:" + $_.Exception.ToString() -fore Yellow
			if ($currentRetry -gt $retries) {
				throw "Can not execute [$commandName] command. The error: " + $_.Exception.ToString()
			} else {
			Write-Host "Sleeping before $currentRetry retry of [$commandName] command"
			Start-Sleep -s 1
			}
			$currentRetry = $currentRetry + 1
		}
	}
	while (!$success)
}

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

nuget_install psake $psakeVersion $psakeDir
Import-Module "$psakeDir\psake.$psakeVersion\tools\psake.psm1";


#------------------------------------------------------------
# Export
#------------------------------------------------------------

export-modulemember -function Koshu-Build, Koshu-Scaffold
export-modulemember -function create_directory, delete_directory, delete_files, copy_files, copy_files_flatten, try_find
export-modulemember -function build_solution, pack_solution, nuget_install, exec_retry
export-modulemember -function invoke_ternary
export-modulemember -alias ?:
export-modulemember -variable koshu