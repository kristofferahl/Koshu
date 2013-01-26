$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "Koshu-Scaffold" {

	Context "scaffolds a new build" {

		Koshu-Scaffold build -rootDir $TestDrive

		It "creates koshu.ps1" {
			(test-path "$TestDrive\koshu.ps1").should.be($true)
		}

		It "creates build.cmd" {
			(test-path "$TestDrive\build.cmd").should.be($true)
		}

		It "creates build.ps1" {
			(test-path "$TestDrive\build.ps1").should.be($true)
		}

    }

	Context "scaffolds a new build template called website" {

		Koshu-Scaffold build -buildName "website" -rootDir $TestDrive $TestDrive

		It "creates koshu.ps1" {
			(test-path "$TestDrive\koshu.ps1").should.be($true)
		}

		It "creates website-build.cmd" {
			(test-path "$TestDrive\website-build.cmd").should.be($true)
		}

		It "creates website-build.ps1" {
			(test-path "$TestDrive\website-build.ps1").should.be($true)
		}

    }

}