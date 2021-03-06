$version = get-content ".\.version"
$buildNumber = "$($env:APPVEYOR_BUILD_NUMBER)"
if ($buildNumber -ne $null -and $buildNumber -ne '') {
	$version = "$version.$buildNumber"
}
$nuget = (resolve-path '.\.nuget\nuget.exe')

write-host "Packaging Koshu v.$version" -fore yellow
mkdir "Build\Artifacts" -erroraction silentlycontinue | out-null
& $nuget pack "Source\Koshu.nuspec" -outputdirectory "Build\Artifacts" -version $version
