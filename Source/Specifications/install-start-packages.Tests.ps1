$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$packagesDir = "$here\..\Packages"
$koshuModule = "$here\..\Koshu\koshu.psm1"
$koshuPluginsDir = "C:\Develop\Koshu.Plugins"

Import-Module $koshuModule -DisableNameChecking -ArgumentList $packagesDir

Describe "install_nuget_package" {
	Context "When installing Koshu.PluginTemplate" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		$result = Install-NugetPackage 'Koshu.PluginTemplate' '*' $TestDrive

		It "installs the package" {
			$result | Should Exist
		}

		It "returns the installation dir" {
			$result.gettype() | Should Be 'string'
			$result | Should Match "Koshu.PluginTemplate.*"
		}
	}

	Context "When installing Koshu.PluginTemplate.0.1.0" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		$result = Install-NugetPackage 'Koshu.PluginTemplate' '0.1.0' $TestDrive

		It "installs the package" {
			$result | Should Exist
		}

		It "returns the installation dir" {
			$expeced = (resolve-path "$TestDrive\Koshu.PluginTemplate.0.1.0").tostring()
			$result.gettype() | Should Be 'string'
			$result | Should Be $expeced
		}
	}

	Context "When installing the same package twice" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		$result1 = Install-NugetPackage 'Koshu.PluginTemplate' '0.1.0' $TestDrive
		$result2 = Install-NugetPackage 'Koshu.PluginTemplate' '0.1.0' $TestDrive

		It "installs the package" {
			$result1 | Should Exist
			$result2 | Should Exist
		}
	}

	Context "When installing non existing package" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		It "should throw" {
			{ Install-NugetPackage 'Koshu.Whatever' '*' $TestDrive } | Should Throw
		}
	}
}

Describe "Install-GitPackage" {
	Context "When installing Koshu.PluginTemplate" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		$result = Install-GitPackage 'Koshu.PluginTemplate' 'git+file:///C/Develop/Koshu.Plugins/Koshu.PluginTemplate' $TestDrive

		It "installs the package" {
			$result | Should Exist
		}

		It "returns the installation dir" {
			$result.gettype() | Should Be 'string'
			$result | Should Be "$TestDrive\Koshu.PluginTemplate.git"
		}

		It "removes the .git dir" {
			"$result\.git" | Should Not Exist
		}
	}

	Context "When installing the same package twice" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue
		$markerfile = "$TestDrive\Koshu.PluginTemplate.git\markerfile.txt"

		$result1 = Install-GitPackage 'Koshu.PluginTemplate' 'git+file:///C/Develop/Koshu.Plugins/Koshu.PluginTemplate' $TestDrive

		"Some content" | out-file $markerfile
		$markerfile | Should Exist

		$result2 = Install-GitPackage 'Koshu.PluginTemplate' 'git+file:///C/Develop/Koshu.Plugins/Koshu.PluginTemplate' $TestDrive

		It "installs the package" {
			$result1 | Should Exist
			$result2 | Should Exist
		}

		It "should clean existing directory by removing it" {
			$markerfile | Should Not Exist
		}
	}

	Context "When installing non existing package" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		It "should throw" {
			{ $result = Install-GitPackage 'Koshu.Whatever' 'git+file:///C/Develop/Koshu.Whatever' $TestDrive } | Should Throw
		}
	}

	Context "When installing package with bad path" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		It "should throw" {
			{ $result = Install-GitPackage 'Koshu.PluginTemplate' 'git+file/C/Develop/Koshu.Whatever' $TestDrive } | Should Throw
		}
	}
}

Describe "Install-DirPackage" {
	Context "When installing Koshu.PluginTemplate" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		$result = Install-DirPackage 'Koshu.PluginTemplate' 'dir+C:\Develop\Koshu.Plugins' $TestDrive

		It "installs the package" {
			$result | Should Exist
		}

		It "returns the installation dir" {
			$result.gettype() | Should Be 'string'
			$result | Should Be "$TestDrive\Koshu.PluginTemplate.dir"
		}
	}

	Context "When installing the same package twice" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue
		$markerfile = "$TestDrive\Koshu.PluginTemplate.dir\markerfile.txt"

		$result1 = Install-DirPackage 'Koshu.PluginTemplate' 'dir+C:\Develop\Koshu.Plugins' $TestDrive

		"Some content" | out-file $markerfile
		$markerfile | Should Exist

		$result2 = Install-DirPackage 'Koshu.PluginTemplate' 'dir+C:\Develop\Koshu.Plugins' $TestDrive

		It "installs the package" {
			$result1 | Should Exist
			$result2 | Should Exist
		}

		It "should clean existing directory by removing it" {
			$markerfile | Should Not Exist
		}
	}

	Context "When installing non existing package" {
		remove-item $TestDrive -recurse -force -erroraction silentlycontinue

		It "should throw" {
			{ $result = Install-DirPackage 'Koshu.Whatever' 'dir+C:\Develop' $TestDrive } | Should Throw
		}
	}
}
