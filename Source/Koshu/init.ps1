param($installPath, $toolsPath, $package)

if (-not(Get-Module -name "koshu")) {
	if ($toolsPath -eq $null) {
		$toolsPath = $MyInvocation.MyCommand.Definition.Replace($MyInvocation.MyCommand.Name, "")
	}

	$koshuModule = Join-Path $toolsPath koshu.psm1
	Import-Module $koshuModule -DisableNameChecking
}

@"
=======================================================
Koshu - The honey flavoured psake build automation tool
=======================================================
"@ | Write-Host