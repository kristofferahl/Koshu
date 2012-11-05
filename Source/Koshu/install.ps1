param($installPath, $toolsPath, $package, $project)

$koshuModule = Join-Path $toolsPath koshu.psm1
import-module $koshuModule

$rootDir			= (resolve-path "$installPath\..\..\..\")
$toolsDirRel		= $toolsPath -replace [regex]::Escape($rootDir), ".\"

if (!(test-path "$rootDir\build.ps1")) {
	copy_files "$toolsPath\Templates" $rootDir "build.ps1"
}

(cat "$toolsPath\build-local.cmd") -replace "koshu-trigger.ps1","$toolsDirRel\koshu-trigger.ps1" | out-file "$rootDir\build-local.cmd" -encoding "Default" -force
(cat "$toolsPath\build-release.cmd") -replace "koshu-trigger.ps1","$toolsDirRel\koshu-trigger.ps1" | out-file "$rootDir\build-release.cmd" -encoding "Default" -force