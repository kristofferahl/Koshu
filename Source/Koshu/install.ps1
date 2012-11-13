param($installPath, $toolsPath, $package, $project)

$rootDir = (resolve-path "$installPath\..\..\..\")
$koshuModule = Join-Path $toolsPath koshu.psm1

Import-Module $koshuModule -DisableNameChecking
Koshu-Scaffold build $project.Name $rootDir