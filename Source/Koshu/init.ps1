param($installPath, $toolsPath, $package)

$koshuModule = Join-Path $toolsPath koshu.psm1
import-module $koshuModule -verbose

@"
=======================================================
Koshu - The honey flavoured psake build automation tool
=======================================================
"@ | Write-Host