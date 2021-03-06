Param(
	[Parameter(Position=0,Mandatory=0)] [string[]]$tasks,
	[Parameter(Position=1,Mandatory=0)] [string]$taskFile,
	[Parameter(Position=2,Mandatory=0)] [hashtable]$parameters = @{},
	[Parameter(Position=3,Mandatory=0)] [hashtable]$properties = @{},
	[Parameter(Position=4,Mandatory=0)] [switch]$load
)

$ErrorActionPreference = 'Stop'  # Ensure errors stops execution
$koshuVersion = '#Version#'
$koshuDir = "#PackagesPath#\Koshu.$koshuVersion"

# Restore koshu nuget package unless present
if (-not (Test-Path $koshuDir)) {
	$paths = (1..3) | % { '.' + ('\*' * $_) }
	$nuget = (Get-ChildItem -Path $paths -Filter NuGet.exe | Select-Object -First 1)
	if ($nuget) { $nuget = $nuget.FullName } else { $nuget = "NuGet.exe" }
	try {
		& $nuget install Koshu -version $koshuVersion -outputdirectory "#PackagesPath#"
	} catch [System.Management.Automation.CommandNotFoundException] {
		throw 'Could not find NuGet.exe and it does not seem to be in your path. Aborting!'
	}
}

# Initialize koshu
& "$koshuDir\tools\init.ps1" -parameters @{ "load" = $load }

if (-not $load) {
	# Trigger koshu
	Invoke-Koshu -taskFile $taskFile -tasks $tasks -parameters $parameters -properties $properties
}
