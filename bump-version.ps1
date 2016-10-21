$file = ".\.version"
$nuspecFile = ".\Source\Koshu.nuspec"
$koshuFile = ".\Source\Koshu\Koshu.psm1"
$installFile = ".\install.ps1"

$currentVersion = get-content $file
write-host "Current version: $currentVersion" -fore yellow
$version = read-host "New version"

new-item -itemtype file -value $version -path $file -force | out-null

# ---------------------------------------------------
# Update nuspec file
# ---------------------------------------------------
$nuspec = [xml](get-content $nuspecFile)
$nuspec.package.metadata.version = "$version"
$nuspec.save($nuspecFile)
write-host "Updated nuspec ($nuspecFile)" -fore cyan
# ---------------------------------------------------

# ---------------------------------------------------
# Update koshu.psm1
# ---------------------------------------------------
$koshu = ((get-content $koshuFile) | % { $_ -replace "'$currentVersion'","'$version'" } | out-string)
new-item -itemtype file -value $koshu -path $koshuFile -force | out-null
write-host "Updated koshu.psm1 ($koshuFile)" -fore cyan
# ---------------------------------------------------

# ---------------------------------------------------
# Update install.ps1 in the root directory
# ---------------------------------------------------
$install = ((get-content $installFile) | % { $_ -replace "'$currentVersion'","'$version'" } | out-string)
new-item -itemtype file -value $install -path $installFile -force | out-null
write-host "Updated install.ps1 ($installFile)" -fore cyan
# ---------------------------------------------------

write-host "Set new version to: $version" -fore green
