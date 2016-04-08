$here			= Split-Path -Parent $MyInvocation.MyCommand.Path
$koshuDir		= "$here\..\Koshu"

. "$koshuDir\koshu-helpers.ps1"

Describe "koshu.ps1" {

	$source			= "$koshuDir\Templates\koshu.ps1"
	$destination	= "$TestDrive\koshu.ps1"
	$version		= get-content "$here\..\..\.version"
	$packagesDir	= ".\Source\Packages"

	Context "when nuget.exe is found in subdirectory" {

		scaffold_koshutrigger $source $destination $version $packagesDir

		$nugetSource = "${env:ProgramFiles(x86)}\Nuget\NuGet.exe"
		$nugetDestinationDir = "$TestDrive\Source\.nuget"

		if (test-path $nugetSource) {
			$nugetDestination = "$nugetDestinationDir\NuGet.exe"
			(New-Item $nugetDestinationDir -Type directory -Force)
			(New-Object System.Net.WebClient).DownloadFile($nugetSource, $nugetDestination)
		} else {
			nuget install Nuget.CommandLine -outputdirectory $nugetDestinationDir
		}

		$currentDir = Get-Location
		Set-Location $TestDrive

		.$destination -load

		Set-Location $currentDir

		It "restores koshu and psake nuget packages" {
			"$TestDrive\Source\Packages\Koshu.$version" | Should Exist
		}

    }

	Context "when nuget is in the path" {

		if ($env:Path.Contains("c:\Nuget-Console\;") -eq $false) {
			$env:Path = $env:Path.TrimEnd(';')
			$env:Path = $env:Path + ";c:\Nuget-Console\;"
		}

		scaffold_koshutrigger $source $destination $version $packagesDir

		$currentDir = Get-Location
		Set-Location $TestDrive

		.$destination -load

		Set-Location $currentDir

		It "restores koshu and psake nuget packages" {
			"$TestDrive\Source\Packages\Koshu.$version" | Should Exist
		}

    }

}
