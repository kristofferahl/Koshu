$version = get-content ".\.version"
$buildNumber = $env:APPVEYOR_BUILD_NUMBER
if ($buildNumber -ne $null -and $buildNumber -ne '') {
	$verion = "$version.$buildNumber"
}

write-host "Current version: $version" -fore yellow

mkdir "Build\Artifacts" -erroraction silentlycontinue | out-null
nuget pack "Source\Koshu.nuspec" -outputdirectory "Build\Artifacts"
