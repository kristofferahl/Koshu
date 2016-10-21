# variables
$version = '0.8.0'
$github = "https://raw.github.com/kristofferahl/Koshu"
$here = get-location
$koshu = "$here\koshu.ps1"
$packagesDir = ".\Source\packages"

write-host "Installing Koshu" -fore cyan

$branchOrTag = read-host "Version to install ($version)"
if ($branchOrTag -eq $null -or $branchOrTag -eq '') {
	$branchOrTag = "$version"
}

$newPackagesDir = read-host "Nuget package directory ($packagesDir)"
if ($newPackagesDir -ne $null -and $newPackagesDir -ne '') {
	$packagesDir = $newPackagesDir
}

function Download-File {
	param (
		[string]$url,
		[string]$file
	)
	write-host "downloading $url to $file"
	$downloader = new-object system.net.webclient
	$downloader.downloadfile($url, $file)
}

download-file "$github/$branchOrTag/Source/Koshu/Templates/koshu.ps1" $koshu

$content = ((get-content $koshu) |
	% { $_ -replace "#Version#",$version } |
		% { $_ -replace "#PackagesPath#",$packagesDir } |
			out-string).trimend([Environment]::NewLine)
new-item -itemtype file -value $content -path $koshu -force | out-null
write-host "Installed Koshu $version"

.\koshu.ps1 -load
