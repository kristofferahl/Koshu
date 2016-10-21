$version = get-content ".\.version"
$buildNumber = "$($env:APPVEYOR_BUILD_NUMBER)"

write-host "Packaging Koshu v.$version" -fore yellow

mkdir "Build\Artifacts" -erroraction silentlycontinue | out-null
nuget pack "Source\Koshu.nuspec" -outputdirectory "Build\Artifacts" -version $version

if ($buildNumber -ne $null -and $buildNumber -ne '') {
	nuget pack "Source\Koshu.nuspec" -outputdirectory "Build\Artifacts" -version "$version.$buildNumber"
}
