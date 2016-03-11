#------------------------------------------------------------
# Variables
#------------------------------------------------------------

$script:koshu		= @{}
$koshu.version		= '0.7.0'
$koshu.verbose		= $false
$koshu.context		= new-object system.collections.stack # holds onto the current state of all variables
$koshu.dir			= $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "") -replace ".$"
$koshu.psakeDir		= ((Resolve-Path $koshu.dir) | Split-Path -parent | Split-Path  -parent)
$koshu.psakeVersion	= '4.5.0'
$koshu.config       = @{ defaultTaskFile = 'koshufile.ps1' }

#------------------------------------------------------------
# Tasks
#------------------------------------------------------------

function Invoke-Koshu {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory = 0)] [string] $taskFile,
		[Parameter(Position = 1, Mandatory = 0)] [string[]] $tasks = @(),
		[Parameter(Position = 2, Mandatory = 0)] [hashtable] $properties = @{},
		[Parameter(Position = 3, Mandatory = 0)] [switch] $nologo = $false
	)

	if (-not $nologo) {
		Write-Host "Koshu - version $($koshu.version)"
		Write-Host 'Copyright (c) 2012 Kristoffer Ahl'
		Write-Host ''
	}

	if ($taskFile -eq $null -or $taskFile -eq '') {
		$taskFile = $koshu.config.defaultTaskFile
	}

	if ("$taskFile".EndsWith('.ps1') -eq $false) {
		$taskFile = "$taskFile.ps1"
	}

	if (-not (test-path $taskFile)) {
		$taskFile = find_up $taskFile . -file
	}

	assert ($taskFile -ne $null -and $taskFile -ne '' -and (test-path $taskFile)) "Taskfile not found: $taskFile"

	$koshu.context.push(@{
		"packagesDir" = (resolve-path "$($koshu.dir)\..\..")
		"packages" = [ordered]@{}
		"config" = [ordered]@{}
		"initParameters" = @{
			"rootDir" = ($taskFile | split-path -parent)
			"taskFile" = $taskFile
			"tasks" = $tasks
			"properties" = $properties
		}
	})

	Write-Host "Invoking psake with properties:" ($properties | Out-String)
	Invoke-Psake -buildFile $taskFile -taskList $tasks -properties $properties -initialization {
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
	} -nologo:$nologo;

	if ($psake.build_success -eq $false) {
		if ($lastexitcode -ne 0) {
			Write-Host "Koshu failed! Exit code: $lastexitcode." -fore red;
			exit $lastexitcode
		} else {
			Write-Host "Koshu failed!" -fore red;
			exit 1
		}
	} else {
		exit 0
	}
}

function Koshu-Scaffold {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$template,
		[Parameter(Position=1,Mandatory=0)][string]$productName='Product.Name',
		[Parameter(Position=2,Mandatory=0)][string]$taskfileName='koshufile',
		[Parameter(Position=3,Mandatory=0)][string]$target='',
		[Parameter(Position=4,Mandatory=0)][string]$rootDir='.\'
	)

	assert ($template -ne $null -and $template -ne "") "No template name specified!"

	Write-Host "Scaffolding Koshu template" $template

	if ("$rootDir".EndsWith("\") -eq $true) {
		$rootDir = $rootDir -replace ".$"
	}

	if ($productName -eq 'Product.Name') {
		try {
			$productName = [IO.Path]::GetFilenameWithoutExtension((Split-Path -Path $dte.Solution.FullName -Leaf))
		} catch {}
	}

	$template				= $template.ToLower()
	$target					= (?: {$target -ne $null -and $target -ne ''} {"$target"} {"default"}).ToString().ToLower()

	$taskfileName			= (?: {$taskfileName -ne $null -and $taskfileName -ne ''} {"$taskfileName"} {"koshufile"}).ToString().ToLower()
	$taskfileFullName		= "$taskfileName.ps1"
	$taskfile 				= "$rootDir\$taskfileFullName"

	$triggerfileName		= (?: {$taskfileName -ne 'koshufile'} {"$taskfileName"} {"koshu"}).ToString().ToLower()
	$triggerfileFullName	= "$triggerfileName.cmd"
	$triggerfile 			= "$rootDir\$triggerfileFullName"

	$koshufileFullName		= 'koshu.ps1'
	$koshufile				= "$rootDir\$koshufileFullName"
	$packagesDir			= (Resolve-Path "$($koshu.dir)\..\..") -replace [regex]::Escape((Resolve-Path $rootDir)), "."

	scaffold_koshutrigger "$($koshu.dir)\Templates\koshu.ps1" $koshufile $koshu.version $packagesDir
	scaffold_triggercmd "$($koshu.dir)\Templates\trigger.cmd" $triggerfile $target $taskfileFullName
	scaffold_taskfile "$($koshu.dir)\Templates\$template.ps1" $taskfile $productName
}

function Koshu-ScaffoldPlugin() {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$pluginName=$(read-host "Plugin name: "),
		[Parameter(Position=1,Mandatory=0)][string]$templateName='Koshu.PluginTemplate',
		[Parameter(Position=2,Mandatory=0)][string]$templateVersion='',
		[Parameter(Position=3,Mandatory=0)][string]$destinationDir='.\koshu-plugins'
	)

	assert ($pluginName -ne $null -and $pluginName -ne "") "No plugin name specified!"
	assert ($templateName -ne $null -and $templateName -ne "") "No template name specified!"
	assert ($templateVersion -ne $null) "No template version specified!"

	if ($destinationDir -eq $null -or $destinationDir -eq "") {
		$destinationDir = '.\koshu-plugins'
	}

	$installParameters = @{
		"rootDir" = "$destinationDir\$pluginName"
		"pluginName" = $pluginName
	}

	write-host "Scaffolding Koshu plugin ($pluginName)" -fore yellow

	write-host "Installing package to '$($installParameters.rootDir)'"
	if (test-path $installParameters.rootDir) {
		throw "The plugin directory '$($installParameters.rootDir)' already exists!"
	}

	$installation = Koshu-InstallPackage -name $templateName -version $templateVersion -destinationDir $destinationDir -installParameters $installParameters

	if ($installation.directory -ne $installParameters.rootDir) {
		write-host "Renaming $($installation.directory) to $($installParameters.pluginName)."
		rename-item $installation.directory -newname $($installParameters.pluginName)
	}

	remove-item "$($installParameters.rootDir)\$name*.nupkg" -force -erroraction silentlycontinue
}

function Koshu-InstallPackage {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$name,
		[Parameter(Position=1,Mandatory=0)][string]$version='',
		[Parameter(Position=2,Mandatory=1)][string]$destinationDir,
		[Parameter(Position=3,Mandatory=1)][hashtable]$installParameters
	)

	assert ($name -ne $null -and $name -ne '') "No name specified."
	assert ($version -ne $null) "No version specified."
	assert ($destinationDir -ne $null -and $destinationDir -ne '') "No destination directory specified."

	$packageType		= $null
	$isGitPackage		= ($version -like "git+*" -or $version -like "git:*")
	$isDirPackage		= ($version -like "dir+*")
	$isNugetPackage		= ((-not $isGitPackage) -and (-not $isDirPackage))

	if ($isGitPackage) {
		$packageType = 'git'
		$installationDir = Install-GitPackage $name $version $destinationDir
	}

	if ($isDirPackage) {
		$packageType = 'dir'
		$installationDir = Install-DirPackage $name $version $destinationDir
	}

	if ($isNugetPackage) {
		$packageType = 'nuget'
		if ($version -eq $null -or $version -eq '') {
			$version = '*'
		}
		$installationDir = Install-NugetPackage $name $version $destinationDir
	}

	$installFile = "$installationDir\tools\install.ps1"
	$hasManifest = $false
	if ((test-path "$installationDir\koshu.manifest") -eq $true) {
		$hasManifest = $true
		$manifestPath = get-content "$installationDir\koshu.manifest"
		$installFile = "$installationDir\$manifestPath\install.ps1"
	}

	if (test-path $installFile) {
		$installParameters.installationDir = $installationDir
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

function Koshu-InitPackage {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$packageDir,
		[Parameter(Position=1,Mandatory=1)][hashtable]$initParameters,
		[Parameter(Position=2,Mandatory=1)][hashtable]$config
	)

	assert ($packageDir -ne $null -and $name -ne '') "No package directory specified."

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

function Install-GitPackage {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$name,
		[Parameter(Position=1,Mandatory=1)][string]$repository,
		[Parameter(Position=2,Mandatory=1)][string]$destinationDir
	)
	write-host "Installing package $name from git ($repository)"

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

function Install-DirPackage {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$name,
		[Parameter(Position=1,Mandatory=1)][string]$sourceDir,
		[Parameter(Position=2,Mandatory=1)][string]$destinationDir
	)
	write-host "Installing package $name from directory ($sourceDir)"

	$sourceDir = $sourceDir -replace 'dir\+',''
	$sourceDir = "$sourceDir\$name"

	if (-not (test-path $sourceDir)) {
		throw "No package found at $sourceDir!"
	}

	$installationDir = "$destinationDir\$name.dir"

	if (test-path $installationDir) {
		remove-item $installationDir -recurse -force
	}

	copy-item -path $sourceDir -destination $installationDir -recurse

	return ([string]$installationDir)
}

function Install-NugetPackage {
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=1)][string]$name,
		[Parameter(Position=1,Mandatory=1)][string]$version,
		[Parameter(Position=2,Mandatory=1)][string]$destinationDir
	)
	write-host "Installing package $name.$version from nuget"

	if ($version -ne '*') {
		$output = find_and_execute "NuGet.exe" "install $name -version $version -outputdirectory $destinationDir"
		write-host $output
	} else {
		$output = find_and_execute "NuGet.exe" "install $name -prerelease -outputdirectory $destinationDir"
		write-host $output
		if ($output -match "(.*)$name (?<version>(.*))\'(.*)") {
			$version = $matches.version
		} else {
			throw "Failed to parse the nuget package version from the command output!"
		}
	}

	$installationDir = "$destinationDir\$name.$version"

	return ([string]$installationDir)
}

#------------------------------------------------------------
# Psake extensions
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

#------------------------------------------------------------
# Includes
#------------------------------------------------------------

. "$($koshu.dir)\koshu-functions.ps1"
. "$($koshu.dir)\koshu-helpers.ps1"

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
    $koshu.psakeDir = $Args[0] -as [string]
	Write-Host "Overriding psake directory with argument $($koshu.psakeDir)"
}

nuget_exe install psake -version $koshu.psakeVersion -outputdirectory $koshu.psakeDir
if(-not(Get-Module -name "psake")) {
	Import-Module "$($koshu.psakeDir)\psake.$($koshu.psakeVersion)\tools\psake.psm1"
}

#------------------------------------------------------------
# Export
#------------------------------------------------------------

export-modulemember -function Invoke-Koshu, Koshu-Scaffold, Koshu-ScaffoldPlugin, Koshu-InstallPackage, Koshu-InitPackage
export-modulemember -function Packages, Config
export-modulemember -function Install-NugetPackage, Install-GitPackage, Install-DirPackage
export-modulemember -function create_directory, delete_directory, delete_files, copy_files, copy_files_flatten, find_down, find_up
export-modulemember -function build_solution, pack_solution
export-modulemember -function nuget_exe, run, exec_retry
export-modulemember -function invoke_ternary
export-modulemember -alias ?:
export-modulemember -variable koshu