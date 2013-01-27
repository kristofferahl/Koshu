$here			= Split-Path -Parent $MyInvocation.MyCommand.Path
$koshuDir		= "$here\..\Koshu"

. "$koshuDir\koshu-helpers.ps1"

Describe "koshu.ps1" {

	Context "when nuget is in the path" {

		$source			= "$koshuDir\Templates\koshu.ps1"
		$destination	= "$TestDrive\koshu.ps1"
		$version		= "0.3.0"
		$packagesDir	= ".\Source\Packages"
		
		scaffold_koshufile $source $destination $version $packagesDir
		Set-Content -Value "properties {}; task default -depends doit; task doit {};" -Path "$TestDrive\build.ps1"
		
		$currentDir = Get-Location
		Set-Location $TestDrive
		
		.$destination build doit
		
		Set-Location $currentDir
        
		It "restores koshu and psake nuget packages" {
			(test-path "$TestDrive\Source\Packages\Koshu.0.3.0").should.be($true)
		}
		
    }

}