$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"
$koshuPluginsDir = "C:\Develop\Koshu.Plugins"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "Koshu-InstallPackage" {
	Context "When installing Koshu.PluginTemplate from nuget" {
		$installParams = @{
			"Param1"="Param1Value"
			"Param2"="Param2Value"
		}
		$result = Koshu-InstallPackage -name 'Koshu.PluginTemplate' -version '0.1.1' -destinationDir $TestDrive -installParameters $installParams

		It "installs the package" {
			$result.directory | Should Exist
		}

		It "returns the installation dir" {
			$result.directory.gettype() | Should Be 'string'
			$result.directory | Should Be "$TestDrive\Koshu.PluginTemplate.0.1.1"
		}

		It "returns the installation dir name" {
			$result.directoryName.gettype() | Should Be 'string'
			$result.directoryName | Should Be "Koshu.PluginTemplate.0.1.1"
		}

		It "returns the manifest status" {
			$result.manifest.gettype() | Should Be 'bool'
			$result.manifest | Should Be $true
		}

		It "returns the installation file path" {
			$result.installFile.gettype() | Should Be 'string'
			$result.installFile | Should Be "$TestDrive\Koshu.PluginTemplate.0.1.1\tools\install.ps1"
		}

		It "returns the installation parameters" {
			$result.installParameters.gettype() | Should Be 'hashtable'
			$result.installParameters | Should Be $installParams
		}

		It "returns the package type parameters" {
			$result.packageType.gettype() | Should Be 'string'
			$result.packageType | Should Be 'nuget'
		}
	}

	Context "When installing Koshu.PluginTemplate from git" {
		$installParams = @{
			"Param1"="Param1Value"
			"Param2"="Param2Value"
		}
		$result = Koshu-InstallPackage -name 'Koshu.PluginTemplate' -version 'git+file:///C/Develop/Koshu.Plugins/Koshu.PluginTemplate' -destinationDir $TestDrive -installParameters $installParams

		It "installs the package" {
			$result.directory | Should Exist
		}

		It "returns the installation dir" {
			$result.directory.gettype() | Should Be 'string'
			$result.directory | Should Be "$TestDrive\Koshu.PluginTemplate.git"
		}

		It "returns the installation dir name" {
			$result.directoryName.gettype() | Should Be 'string'
			$result.directoryName | Should Be "Koshu.PluginTemplate.git"
		}

		It "returns the manifest status" {
			$result.manifest.gettype() | Should Be 'bool'
			$result.manifest | Should Be $true
		}

		It "returns the installation file path" {
			$result.installFile.gettype() | Should Be 'string'
			$result.installFile | Should Be "$TestDrive\Koshu.PluginTemplate.git\tools\install.ps1"
		}

		It "returns the installation parameters" {
			$result.installParameters.gettype() | Should Be 'hashtable'
			$result.installParameters | Should Be $installParams
		}

		It "returns the package type parameters" {
			$result.packageType.gettype() | Should Be 'string'
			$result.packageType | Should Be 'git'
		}
	}

	Context "When installing Koshu.PluginTemplate from dir" {
		$installParams = @{
			"Param1"="Param1Value"
			"Param2"="Param2Value"
		}
		$result = Koshu-InstallPackage -name 'Koshu.PluginTemplate' -version "dir+$koshuPluginsDir" -destinationDir $TestDrive -installParameters $installParams

		It "installs the package" {
			$result.directory | Should Exist
		}

		It "returns the installation dir" {
			$result.directory.gettype() | Should Be 'string'
			$result.directory | Should Be "$TestDrive\Koshu.PluginTemplate.dir"
		}

		It "returns the installation dir name" {
			$result.directoryName.gettype() | Should Be 'string'
			$result.directoryName | Should Be "Koshu.PluginTemplate.dir"
		}

		It "returns the manifest status" {
			$result.manifest.gettype() | Should Be 'bool'
			$result.manifest | Should Be $true
		}

		It "returns the installation file path" {
			$result.installFile.gettype() | Should Be 'string'
			$result.installFile | Should Be "$TestDrive\Koshu.PluginTemplate.dir\tools\install.ps1"
		}

		It "returns the installation parameters" {
			$result.installParameters.gettype() | Should Be 'hashtable'
			$result.installParameters | Should Be $installParams
		}

		It "returns the package type parameters" {
			$result.packageType.gettype() | Should Be 'string'
			$result.packageType | Should Be 'dir'
		}
	}
}
