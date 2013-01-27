Param(
	[Parameter(Position=0,Mandatory=1)] [string]$buildFile,
	[Parameter(Position=1,Mandatory=1)] [string]$target
)

# Ensure errors fail the build
$ErrorActionPreference = 'Stop'

# Restore koshu nuget package
try {
	nuget install Koshu -version #Version# -outputdirectory "#PackagesPath#"
} catch [System.Management.Automation.CommandNotFoundException] {
	throw 'Nuget.exe is not in your path! Add it to your environment variables.'
}

# Initialize koshu
#PackagesPath#\Koshu.#Version#\tools\init.ps1

# Trigger koshu
Koshu-Build $buildFile $target