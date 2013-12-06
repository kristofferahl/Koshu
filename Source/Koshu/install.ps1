param($installPath, $toolsPath, $package, $project)

$rootDir = (resolve-path "$installPath\..\..\..\")

if(-not(Get-Module -name "koshu")) {
	$koshuModule = Join-Path $toolsPath koshu.psm1
	Import-Module $koshuModule -DisableNameChecking
}

Koshu-Scaffold -template build -projectName $project.Name -rootDir $rootDir