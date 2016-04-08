function scaffold_koshutrigger($source, $destination, $version, $packagesDir) {
	if (!(test-path $destination)) {
		get-content $source |
			% { $_ -replace "#Version#",$version } |
				% { $_ -replace "#PackagesPath#",$packagesDir } |
					out-file $destination -encoding "Default" -force

		write-output "- Created koshu trigger $destination"
	} else {
		write-output "- $destination already exists"
	}
}

function scaffold_triggercmd($source, $destination, $tasks, $taskfile) {
	if (!(test-path $destination)) {
		$triggerArgs = ''
		if ($tasks -ne 'default') { $triggerArgs = "$tasks " }
		if ($taskfile -ne 'koshufile.ps1') { $triggerArgs += "$taskfile " }
		$triggerArgs += '%*'
		(get-content $source) -replace 'koshuargs',$triggerArgs | out-file $destination -encoding "Default" -force
		write-output "- Created trigger cmd $destination. Taskfile: $taskfile. Tasks: $tasks."
	} else {
		write-output "- $destination already exists"
	}
}

function scaffold_taskfile($source, $destination, $productName) {
	if (!(test-path $destination)) {
		(get-content $source) -replace "Product.Name", $productName | out-file $destination -encoding "Default" -force
		write-output "- Created taskfile $destination"
	} else {
		write-output "- $destination already exists"
	}
}
