Param(
	[Parameter(Position=0,Mandatory=1)] [string]$buildFile,
	[Parameter(Position=1,Mandatory=1)] [string]$target
)

# Ensure errors fail the build
$ErrorActionPreference = 'Stop'

# Restore koshu nuget package
nuget install Koshu -version #Version# -outputdirectory "#PackagesPath#"

# Initialize koshu
#PackagesPath#\Koshu.#Version#\tools\init.ps1

# Trigger koshu
Koshu-Build $buildFile $target