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
	$copiedFiles = 0
	if (test-path $source) {
		New-Item -ItemType Directory -Path $destination -Force | Out-Null

		$fullSourcePath = (Resolve-Path $source)
		$fullDestinationPath = (Resolve-Path $destination)

		Get-ChildItem $source -Recurse -Include $include -Exclude $exclude | % {
			$itemPath = $_.FullName.Replace($fullSourcePath, $fullDestinationPath)

			if ($koshu.verbose -eq $true) {
				Write-Host "Copying '$_' to '$itemPath'"
			}

			if (!($_.PSIsContainer)) {
				New-Item -ItemType File -Path $itemPath -Force | Out-Null
			}
			Copy-Item -Force -Path $_ -Destination $itemPath | Out-Null

			$copiedFiles++
		}
	}
	Write-Host "Copied $copiedFiles $(if ($copiedFiles -eq 1) { "item" } else { "items" }) from '$source' to '$destination'."
}

function copy_files_flatten($source, $destination, $filter) {
	create_directory $destination
	foreach($f in $filter.split(",")) {
		Get-ChildeItem $source -filter $f.trim() -r | Copy-Item -dest $destination
	}
}

function find_down($pattern, $path, $maxLevels=3, [switch]$file, [switch]$directory) {
	if ($file -ne $true -and $directory -ne $true) {
		throw "You must pass a switch for -file or -directory."
	}

	if (test-path $path) {
		$paths = (1..$maxLevels) | % { '' + $path + ('\*' * $_) }
		if ($file) { $matcher = { get-childitem -path $paths -filter $pattern | ?{ -not $_.PsIsContainer } } }
		if ($directory) { $matcher = { get-childitem -path $paths -filter $pattern | ?{ $_.PsIsContainer } } }

		$matches = @((& $matcher))
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

	$patternDrive = (split-path -qualifier $pattern -erroraction silentlycontinue)
	$patternIsAbsolutePath = ($patternDrive -ne $null) -and (New-Object System.IO.DriveInfo($patternDrive)).DriveType -ne 'NoRootDirectory'

	if ($patternIsAbsolutePath) { return $null }

	if (test-path $path) {
		if ($file) {
			$type = "File"
			$matcher = {get-childitem -path $path -filter $pattern -erroraction silentlycontinue | ?{ -not $_.PsIsContainer }}
		}

		if ($directory) {
			$type = "Directory"
			$matcher = {get-childitem -path $path -filter $pattern -erroraction silentlycontinue | ?{ $_.PsIsContainer }}
		}

		$matches = @((& $matcher))

		if ($matches.length -lt 1) {
			write-host "$type '$pattern' not found in '$path'. Trying one level up."

			$levelsUp = 0
			do {
				$path = "$path\.."

				if (test-path $path) {
					$path = (resolve-path $path)
					$matches = @((& $matcher))

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

function nuget_exe() {
	find_and_execute "NuGet.exe" $args
}

function run([string]$exe) {
	find_and_execute $exe $args
}

function find_and_execute([string]$commandName, $arguments) {
	$command = find_down $commandName (resolve-path .) -file

	if ($command -eq $null) { $command = $commandName }
	if ($command -eq $null)  { return }

	try {
		& $command | out-null
	} catch [System.Management.Automation.CommandNotFoundException] {
		throw "Could not find '$commandName' and it does not seem to be in your path!"
	}

	$fullCommand = "& '$command' $arguments"
	((invoke-expression $fullCommand) 2>&1) | out-string

	if ($lastExitCode -ne 0) {
		throw "An error occured when invoking command: '$fullCommand'."
	}
}

function exec_retry([scriptblock]$command, [string]$commandName, [int]$retries = 3) {
	$currentRetry = 0
	$success = $false

	do {
		try {
			& $command
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

function build {
	param(
		[Parameter(Position = 0, Mandatory = 1)] [string] $file,
		[Parameter(Position = 1, Mandatory = 0)] [string] $destination = $null,
		[Parameter(Position = 2, Mandatory = 0)] [string] $configuration = 'release'
	)

	Assert (Test-Path $file) "$file could not be found"

	$buildVerbosity = 'quiet'
	if ($koshu.verbose -eq $true) {
		$buildVerbosity = 'minimal'
	}

	if ($destination -eq $null -or $destination -eq '') {
		exec {
			msbuild $file `
				/target:Rebuild `
				/property:Configuration=$configuration `
				/verbosity:$buildVerbosity
		}
	} else {
		$type = [IO.Path]::GetExtension((Resolve-Path $file))
		if ($type -eq ".csproj" -or $type -eq ".vbproj") {
			$subDir = [IO.Path]::GetFileNameWithoutExtension((Resolve-Path $file))
			$destination = "$destination\$subDir"
		} else {
			throw "Solution files are not supported with the -destination option"
		}

		create_directory $destination | Out-Null

		exec {
			msbuild $file `
				/target:Publish `
				/property:Configuration=$configuration `
				/property:_PackageTempDir=$artifactDir `
				/property:AutoParameterizationWebConfigConnectionStrings=False `
				/verbosity:$buildVerbosity
		}

		if ((Get-ChildItem $destination | Measure-Object).Count -eq 0) {
			$parentDir = Split-Path $file -parent
			copy_files -source "$parentDir\bin\$configuration" -destination $destination
		}
	}
}
