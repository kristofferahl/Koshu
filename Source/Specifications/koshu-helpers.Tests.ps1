$here			= Split-Path -Parent $MyInvocation.MyCommand.Path
$koshuDir		= "$here\..\Koshu"
$version		= "99.99.99"
$packagesDir	= ".\Source\Packages"

. "$koshuDir\koshu-helpers.ps1"

Describe "scaffold_koshufile" {

	scaffold_koshufile "$koshuDir\Templates\koshu.ps1" "$TestDrive\koshu.ps1" $version $packagesDir

    It "copies koshu.ps1 to target directory" {
		"$TestDrive\koshu.ps1" | Should Exist
    }
	
	It "replaces version token" {
		$content = (Get-Content "$TestDrive\koshu.ps1" | Out-String)
		$content.Contains($version) | Should Be $true
    }
	
	It "replaces packages path token" {
		$content = (Get-Content "$TestDrive\koshu.ps1" | Out-String)
		$content.Contains($packagesDir) | Should Be $true
	}

}