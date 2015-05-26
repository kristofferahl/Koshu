$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "Koshu-Scaffold" {

	Context "scaffolds a new build" {

		Koshu-Scaffold -template build -rootDir $TestDrive

		It "creates koshu.ps1" {
			"$TestDrive\koshu.ps1" | Should Exist
		}

		It "creates koshu.cmd" {
			"$TestDrive\koshu.cmd" | Should Exist
		}

		It "creates koshufile.ps1" {
			"$TestDrive\koshufile.ps1" | Should Exist
		}

		It "has taskfile set to koshufile.ps1 in koshu.cmd" {
			"$TestDrive\koshu.cmd" | Should Contain "koshufile.ps1"
		}

		It "has target set to compile in koshu.cmd" {
			"$TestDrive\koshu.cmd" | Should Contain "default"
		}

	}

	Context "scaffolds a new build template called build-web" {

		Koshu-Scaffold -template build -taskfilename "build-web" -rootDir $TestDrive

		It "creates koshu.ps1" {
			"$TestDrive\koshu.ps1" | Should Exist
		}

		It "creates build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Exist
		}

		It "creates build-web.ps1" {
			"$TestDrive\build-web.ps1" | Should Exist
		}

		It "has taskfile set to build-web.ps1 in build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Contain "build-web.ps1"
		}

		It "has target set to compile in build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Contain "default"
		}

	}

	Context "scaffolds a new build template called build-web with target compile" {

		Koshu-Scaffold -template build -taskfilename "build-web" -target "compile" -rootDir $TestDrive

		It "creates koshu.ps1" {
			"$TestDrive\koshu.ps1" | Should Exist
		}

		It "creates build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Exist
		}

		It "creates build-web.ps1" {
			"$TestDrive\build-web.ps1" | Should Exist
		}

		It "has taskfile set to build-web.ps1 in build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Contain "build-web.ps1"
		}

		It "has target set to compile in build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Contain "compile"
		}

    }

}