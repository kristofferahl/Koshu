$version = get-content ".\.version"
$pesterVersion = '3.4.0'
$nuget = (resolve-path '.\.nuget\nuget.exe')

write-host "Preparing testrun..." -fore cyan

& $nuget install Pester -Version $pesterVersion -OutputDirectory "Source\packages"

rmdir 'Build\Test' -recurse -force -erroraction silentlycontinue | out-null
mkdir 'Build\Test' -force | out-null
mkdir 'Build\Test\packages' -force | out-null
$buildTestPackages = (resolve-path 'Build\Test\packages')

if ($env:APPVEYOR_BUILD_NUMBER -ne $null -and $env:APPVEYOR_BUILD_NUMBER -ne '') {
	$version = "$version.$($env:APPVEYOR_BUILD_NUMBER)"
} else {
	$version = "$version.$(get-random -minimum 1 -maximum 9999)"
}

$env:BUILD_KOSHU_VERSION = $version

& $nuget sources add -name "KoshuTestFeed" -source "$buildTestPackages"
& $nuget pack 'Source\Koshu.nuspec' -Version $version -OutputDirectory $buildTestPackages -NoPackageAnalysis

write-host "Running Pester. Koshu build version $($env:BUILD_KOSHU_VERSION)" -fore cyan

try	{
	Import-Module ".\Source\packages\Pester.$pesterVersion\tools\Pester.psm1"
	Invoke-Pester '.\Source\Specifications\*' -EnableExit
} finally {
	& $nuget sources remove -name "KoshuTestFeed"
}
