$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "Koshu-Scaffold" {

	Context "scaffolds a new build" {

		Koshu-Scaffold build -rootDir $TestDrive

		It "creates koshu.ps1" {
			"$TestDrive\koshu.ps1" | Should Exist
		}

		It "creates build.cmd" {
			"$TestDrive\build.cmd" | Should Exist
		}

		It "creates build.ps1" {
			"$TestDrive\build.ps1" | Should Exist
		}

    }

	Context "scaffolds a new build template called website" {

		Koshu-Scaffold build -buildName "website" -rootDir $TestDrive $TestDrive

		It "creates koshu.ps1" {
			"$TestDrive\koshu.ps1" | Should Exist
		}

		It "creates website-build.cmd" {
			"$TestDrive\website-build.cmd" | Should Exist
		}

		It "creates website-build.ps1" {
			"$TestDrive\website-build.ps1" | Should Exist
		}

    }

}