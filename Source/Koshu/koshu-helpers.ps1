function scaffold_koshutrigger($source, $destination, $version, $packagesDir) {
	if (!(test-path $destination)) {
		Get-Content $source |
			% { $_ -replace "#Version#",$version } |
				% { $_ -replace "#PackagesPath#",$packagesDir } |
					Out-File $destination -encoding "Default" -force

		Write-Host "Created koshu trigger $destination"
	} else {
		Write-Host "$destination already exists" -fore yellow
	}
}

function scaffold_triggercmd($source, $destination, $target, $taskfile) {
	if (!(test-path $destination)) {
		(get-content $source) -replace "default",$target -replace "koshufile.ps1","$taskfile" | out-file $destination -encoding "Default" -force
		Write-Host "Created trigger cmd $destination. Taskfile: $taskfile. Target: $target."
	} else {
		Write-Host "$destination already exists" -fore yellow
	}
}

function scaffold_taskfile($source, $destination, $productName) {
	if (!(test-path $destination)) {
		(get-content $source) -replace "Product.Name", $productName | out-file $destination -encoding "Default" -force
		Write-Host "Created taskfile $destination"
	} else {
		Write-Host "$destination already exists" -fore yellow
	}
}