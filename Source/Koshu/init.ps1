param($installPath, $toolsPath, $package, $parameters)

if (-not(Get-Module -name "koshu")) {
	if ($toolsPath -eq $null) {
		$toolsPath = $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "")
	}

	$koshuModule = Join-Path $toolsPath koshu.psm1
	Import-Module $koshuModule -DisableNameChecking
}

if (-not $parameters.nologo) {
@"
 _  __         _           
| |/ /___  ___| |__  _   _ 
| ' // _ \/ __| '_ \| | | |
| . \ (_) \__ \ | | | |_| |
|_|\_\___/|___/_| |_|\__,_|
"@ | Write-Host
}

@"
=======================================================
Koshu - The honey flavoured psake build automation tool
=======================================================
"@ | Write-Host