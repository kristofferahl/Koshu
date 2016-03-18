$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "Koshu-Scaffold" {

	Context "scaffolding a new build template" {

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

		It "does not have a taskfile specified in koshu.cmd" {
			"$TestDrive\koshu.cmd" | Should Not Contain "koshufile.ps1"
		}

		It "does not have tasks specified in koshu.cmd" {
			"$TestDrive\koshu.cmd" | Should Not Contain "default"
		}

	}

	Context "scaffolding a new build template with taskfilename" {

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

	}

	Context "scaffolding a new build template with tasks" {

			Koshu-Scaffold -template build -tasks "compile" -rootDir $TestDrive

			It "creates koshu.ps1" {
				"$TestDrive\koshu.ps1" | Should Exist
			}

			It "creates koshu.cmd" {
				"$TestDrive\koshu.cmd" | Should Exist
			}

			It "creates koshufile.ps1" {
				"$TestDrive\koshufile.ps1" | Should Exist
			}

			It "has tasks set to compile in koshu.cmd" {
				"$TestDrive\koshu.cmd" | Should Contain "compile"
			}

	    }

	Context "scaffolding a new build template with taskfilename and tasks" {

		Koshu-Scaffold -template build -taskfilename "build-web" -tasks "compile" -rootDir $TestDrive

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

		It "has tasks set to compile in build-web.cmd" {
			"$TestDrive\build-web.cmd" | Should Contain "compile"
		}

    }

}
