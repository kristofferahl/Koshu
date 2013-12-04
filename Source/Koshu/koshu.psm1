#------------------------------------------------------------
# Variables
#------------------------------------------------------------

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

	if (-not (test-path $buildFile)) {
		$buildFile = find_up $buildFile . -file
	}

	Assert (test-path $buildFile) "Build file not found: $buildFile"

	$koshu.context.push(@{
		"packagesDir" = (resolve-path "$koshuDir\..\..")
		"packages" = [ordered]@{}
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
				$install = (Koshu-InstallPackage -name $_.key -version $_.value -destinationDir $context.packagesDir -installParameters $context.initParameters)
				$context.initParameters.packageDir = $install.directory
				$packageConfig = $context.config.get_item($_.key)
				if ($packageConfig -eq $null) {
					$packageConfig = @{}
				}
				Koshu-InitPackage -packageDir $context.initParameters.packageDir -initParameters $context.initParameters -config $packageConfig
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

function Koshu-ScaffoldPlugin() {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$pluginName=$(read-host "Plugin name: "),
		[Parameter(Position=1,Mandatory=0)][string]$templateName='Koshu.PluginTemplate',
		[Parameter(Position=2,Mandatory=0)][string]$templateVersion='',
		[Parameter(Position=3,Mandatory=0)][string]$destinationDir='.\koshu-plugins'
	)

	Assert ($pluginName -ne $null -and $pluginName -ne "") "No plugin name specified!"
	Assert ($templateName -ne $null -and $templateName -ne "") "No template name specified!"
	Assert ($templateVersion -ne $null) "No template version specified!"

	if ($destinationDir -eq $null -or $destinationDir -eq "") {
		$destinationDir = '.\koshu-plugins'
	}

	$installParameters = @{
		"rootDir" = "$destinationDir\$pluginName"
		"pluginName" = $pluginName
	}

	write-host "Scaffolding Koshu plugin ($pluginName)" -fore yellow

	$installation = Koshu-InstallPackage -name $templateName -version $templateVersion -destinationDir $destinationDir -installParameters $installParameters

	if ($installation.directory -ne $installParameters.rootDir) {
		write-host "Renaming $($installation.directory) to $($installParameters.pluginName)."
		rename-item $installation.directory -newname $($installParameters.pluginName)
	}

	remove-item "$($installParameters.rootDir)\$name*.nupkg" -force -erroraction silentlycontinue
}

function Koshu-InstallPackage([string]$name, [string]$version, [string]$destinationDir, [hashtable]$installParameters) {
	Assert ($name -ne $null -and $name -ne '') "No name specified."
	Assert ($version -ne $null) "No version specified."
	Assert ($destinationDir -ne $null -and $destinationDir -ne '') "No destination directory specified."

	$packageType		= $null
	$isGitPackage		= ($version -like "git+*" -or $version -like "git:*")
	$isDirPackage		= ($version -like "dir+*")
	$isNugetPackage		= ((-not $isGitPackage) -and (-not $isDirPackage))

	if ($isGitPackage) {
		$packageType = 'git'
		$installationDir = install_git_package $name $version $destinationDir "Installing package $name from git ($version)"
	}

	if ($isDirPackage) {
		$packageType = 'dir'
		$installationDir = install_dir_package $name $version $destinationDir "Installing package $name from directory ($version)"
	}

	if ($isNugetPackage) {
		$packageType = 'nuget'
		if ($version -eq $null -or $version -eq '') {
			$version = '*'
		}
		$installationDir = install_nuget_package $name $version $destinationDir "Installing package $name.$version from nuget"
	}

	$installFile = "$installationDir\tools\install.ps1"
	$hasManifest = $false
	if ((test-path "$installationDir\koshu.manifest") -eq $true) {
		$hasManifest = $true
		$manifestPath = get-content "$installationDir\koshu.manifest"
		$installFile = "$installationDir\$manifestPath\install.ps1"
	}

	if (test-path $installFile) {
		. $installFile -parameters $installParameters
	}

	return @{
		"packageType"=$packageType
		"directory"=$installationDir
		"directoryName"=(split-path $installationDir -leaf)
		"manifest"=$hasManifest
		"installFile" = $installFile
		"installParameters" = $installParameters
	}
}

function Koshu-InitPackage([string]$packageDir, [hashtable]$initParameters, [hashtable]$config) {
	$name = ($packageDir | split-path -leaf)
	$destinationDir = $packageDir

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

function install_git_package($name, $repository, $destinationDir, $message) {
	write-host $message

	$value = $null

	$repository = $repository -replace 'git\+', ''

	$pattern = '(?i)#(.*)'
	$result = [Regex]::Matches($repository, $pattern)
	if ($result.success -eq $true) {
		$value = $result.groups[1].value.tostring()
		$repository = $repository -replace $result.value, ''
	}

	$installationDir = "$destinationDir\$name.git"

	if (test-path $installationDir) {
		remove-item $installationDir -recurse -force | out-null
	}
	new-item $installationDir -type directory | out-null

	$cloneCommand = "git clone $repository $installationDir --quiet"
	invoke-expression $cloneCommand

	if ($lastExitCode -ne 0) {
		remove-item $installationDir -recurse -force -erroraction silentlycontinue | out-null
		throw "An error occured! '$cloneCommand'."
	}

	if ($value -ne $null) {
		set-location $installationDir
		write-host "  Checking out $value"

		$checkoutCommand = "git checkout $value --quiet"
		invoke-expression $checkoutCommand

		if ($lastExitCode -ne 0) {
			remove-item $installationDir -recurse -force -erroraction silentlycontinue | out-null
			throw "An error occured! '$checkoutCommand'."
		}
	}

	if (test-path "$installationDir\.git") {
		remove-item "$installationDir\.git" -recurse -force | out-null
	}

	return ([string]$installationDir)
}

function install_dir_package($name, $directory, $destinationDir, $message) {
	write-host $message

	$directory = $directory -replace 'dir\+',''
	$sourceDirectory = "$directory\$name"

	if (-not (test-path $sourceDirectory)) {
		throw "No package found at $sourceDirectory!"
	}

	$installationDir = "$destinationDir\$name.dir"

	if (test-path $installationDir) {
		remove-item $installationDir -recurse -force
	}

	copy-item -path $sourceDirectory -destination $installationDir -recurse

	return ([string]$installationDir)
}

function install_nuget_package($name, $version, $destinationDir, $message) {
	write-host $message

	if ($version -ne '*') {
		$x = find_and_execute "NuGet.exe" "install $name -version $version -outputdirectory $destinationDir"
		write-host $x
	} else {
		$x = find_and_execute "NuGet.exe" "install $name -prerelease -outputdirectory $destinationDir"
		write-host $x
		if ($x -match "(.*)$name (?<version>(.*))\'(.*)") {
			$version = $matches.version
		} else {
			throw "Failed to parse the nuget package version!"
		}
	}

	$installationDir = "$destinationDir\$name.$version"

	return ([string]$installationDir)
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

export-modulemember -function Packages, Config, Koshu-Build, Koshu-Scaffold, Koshu-ScaffoldPlugin, Koshu-InstallPackage, Koshu-InitPackage
export-modulemember -function create_directory, delete_directory, delete_files, copy_files, copy_files_flatten, find_down, find_up
export-modulemember -function build_solution, pack_solution
export-modulemember -function nuget_exe, run, exec_retry
export-modulemember -function invoke_ternary
export-modulemember -function install_nuget_package, install_git_package, install_dir_package
export-modulemember -alias ?:
export-modulemember -variable koshu