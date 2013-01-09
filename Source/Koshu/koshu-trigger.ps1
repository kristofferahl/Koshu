Param(
	[Parameter(Position=0,Mandatory=1)] [string]$buildFile,
	[Parameter(Position=1,Mandatory=0)] [string]$target,
	[Parameter(Position=2,Mandatory=0)] [string]$artifactsDir,
	[Parameter(Position=3,Mandatory=0)] [string]$deploymentDir,
	[Parameter(Position=4,Mandatory=0)] [string]$buildNumber
)

$psakeParameters = @{}

if ($deploymentDir -ne $null -and $deploymentDir -ne '') {
	$psakeParameters.deploymentDir = $deploymentDir;
}

if ($artifactsDir -ne $null -and $artifactsDir -ne '') {
	$psakeParameters.artifactsDir = $artifactsDir;
}

if ($buildNumber -ne $null -and $buildNumber -ne '') {
	$psakeParameters.buildNumber = $buildNumber;
}

if(-not(Get-Module -name "koshu")) {
	Import-Module "$(Split-Path -parent $MyInvocation.MyCommand.Definition)\koshu.psm1"
}

Koshu-Build -buildFile $buildFile -target $target -psakeParameters $psakeParameters