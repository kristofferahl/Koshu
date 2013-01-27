function scaffold_koshufile($source, $destination, $version, $packagesDir) {
	if (!(test-path $destination)) {
		Get-Content $source |
			% { $_ -replace "#Version#",$version } |
				% { $_ -replace "#PackagesPath#",$packagesDir } |
					Out-File $destination -encoding "Default" -force
		
		Write-Host "Created koshu trigger $destination"
	}
}