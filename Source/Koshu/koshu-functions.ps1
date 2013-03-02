function create_directory($directoryName) {
	if (!(test-path $directoryName -pathtype container)) {
		New-Item $directoryName -Type directory -Force -Verbose:$koshu.verbose
	}
}

function delete_directory($directoryName) {
	if (test-path $directoryName -pathtype container) {
		Remove-Item -Recurse -Force $directoryName -Verbose:$koshu.verbose
	}
}

function delete_files($source, $include=@("*"), $exclude=@()) {
	if (test-path $source -pathtype container) {
		Write-Host "Removing files in '$source'. Include '$include'. Exclude '$exclude'"
		Remove-Item -Recurse -Force "$source\*" -Include $include -Exclude $exclude -Verbose:$koshu.verbose
	}
}

function copy_files($source, $destination, $include=@("*.*"), $exclude=@()) {
	if (test-path $source) {
		$copiedFiles = 0
		Write-Host "Copying '$source' to '$destination'. Include '$include'. Exclude '$exclude'"

		New-Item -ItemType Directory -Path $destination -Force | Out-Null

		Get-ChildItem $source -Recurse -Include $include -Exclude $exclude | % {
			$fullSourcePath = (Resolve-Path $source)
			$fullDestinationPath = (Resolve-Path $destination)
			$itemPath = $_.FullName -replace [regex]::Escape($fullSourcePath),[regex]::Escape($fullDestinationPath)

			if ($koshu.verbose -eq $true) { Write-Host "Copying '$_' to '$itemPath'." }

			if (!($_.PSIsContainer)) {
				New-Item -ItemType File -Path $itemPath -Force | Out-Null
			}
			Copy-Item -Force -Path $_ -Destination $itemPath | Out-Null

			$copiedFiles++
		}

		Write-Host "Copied $copiedFiles $(if ($copiedFiles -eq 1) { "item" } else { "items" })."
	}
}

function copy_files_flatten($source, $destination, $filter) {
	create_directory $destination
	foreach($f in $filter.split(",")) {
		Get-ChildeItem $source -filter $f.trim() -r | Copy-Item -dest $destination
	}
}

function find_down($pattern, $path, [switch]$file, [switch]$directory) {
	if ($file -ne $true -and $directory -ne $true) {
		throw "You must pass a switch for -file or -directory."
	}
	
	if (test-path $path) {
		if ($file) { $matcher = {get-childitem -path $path -filter $pattern -recurse -file} }
		if ($directory) { $matcher = {get-childitem -path $path -filter $pattern -recurse -directory} }
		
		$matches = (& $matcher)
		if ($matches -ne $null -and $matches.length -gt 0) {
			return $matches[0].FullName
		}
		return $null
	}
}

function find_up($pattern, $path, $maxLevels=3, [switch]$file, [switch]$directory) {
	if ($file -ne $true -and $directory -ne $true) {
		throw "You must pass a switch for -file or -directory."
	}
	
	if (test-path $path) {
		if ($file) {
			$type = "File"
			$matcher = {get-childitem -path $path -filter $pattern -file}
		}
		
		if ($directory) {
			$type = "Directory"
			$matcher = {get-childitem -path $path -filter $pattern -directory}
		}
	
		$matches = (& $matcher)
		
		if ($matches.length -lt 1) {
			write-host "$type '$pattern' not found in '$path'. Trying one level up."
			
			$levelsUp = 0
			do {
				$path = "$path\.."
				
				if (test-path $path) {
					$path = (resolve-path $path)
					$matches = (& $matcher)
					
					if ($matches.length -lt 1) {
						write-host "$type '$pattern' not found in '$path'. Trying one level up."
					}
				}
				$levelsUp++
			} while ($matches.length -lt 1 -and $levelsUp -lt $maxLevels)
		}
	}

	if ($matches -ne $null -and $matches.length -gt 0) {
		return $matches[0].FullName
	}
	return $null
}

function build_solution($solutionName, $configuration='release') {
	Assert (test-path $solutionName) "$solutionName could not be found"
	$buildVerbosity = 'quiet'
	if ($koshu.verbose -eq $true) {
		$buildVerbosity = 'minimal'
	}
	exec {
		msbuild $solutionName /target:Rebuild /property:Configuration=$configuration /verbosity:$buildVerbosity
	}
}

function pack_solution($solutionName, $destination, $packageName, $configuration='release') {
	Assert (test-path $solutionName) "$solutionName could not be found"
	
	create_directory $destination
	
	$type = [IO.Path]::GetExtension((Resolve-Path $solutionName))
	
	$packageRoot	= (Resolve-Path $destination)
	$packageDir		= "$packageRoot\$packageName"
	
	if ($type -eq ".csproj" -or $type -eq ".vbproj") {
		$subDir = [IO.Path]::GetFileNameWithoutExtension((Resolve-Path $solutionName))
		$packageDir	= "$packageDir\$subDir"
	}

	create_directory $packageDir

	$buildVerbosity = 'quiet'
	if ($koshu.verbose -eq $true) {
		$buildVerbosity = 'minimal'
	}

	exec {
		msbuild $solutionName `
			/target:Publish `
			/property:Configuration=$configuration `
			/property:_PackageTempDir=$packageDir `
			/property:AutoParameterizationWebConfigConnectionStrings=False `
			/verbosity:$buildVerbosity
	}
}

function nuget_install($package, $version, $target='.\') {
	$nuget = (Get-ChildItem -Path . -Filter NuGet.exe -Recurse | Select-Object -First 1)
	if ($nuget) { $nuget = $nuget.FullName } else { $nuget = "NuGet.exe" }
	
	try {
		if ($version -ne $null) {
			& $nuget install $package -Version $version -OutputDirectory $target
		} else {
			& $nuget install $package -OutputDirectory $target
		}
	} catch [System.Management.Automation.CommandNotFoundException] {
		throw 'Could not find NuGet.exe and it does not seem to be in your path! Aborting build.'
	}
}

function exec_retry([scriptblock]$command, [string]$commandName, [int]$retries = 3) {
	$currentRetry = 0
	$success = $false

	do {
		try {
			& $command;
			$success = $true
			Write-Host "Successfully executed [$commandName] command. Number of retries: $currentRetry."
		} catch [System.Exception] {
			Write-Host "Exception occurred while trying to execute [$commandName] command:" + $_.Exception.ToString() -fore Yellow
			if ($currentRetry -gt $retries) {
				throw "Can not execute [$commandName] command. The error: " + $_.Exception.ToString()
			} else {
			Write-Host "Sleeping before $currentRetry retry of [$commandName] command"
			Start-Sleep -s 1
			}
			$currentRetry = $currentRetry + 1
		}
	}
	while (!$success)
}