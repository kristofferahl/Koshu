$here			= Split-Path -Parent $MyInvocation.MyCommand.Path
$koshuDir		= "$here\..\Koshu"
$version		= "99.99.99"
$packagesDir	= ".\Source\Packages"

. "$koshuDir\koshu-helpers.ps1"

Describe "scaffold_koshufile" {

	scaffold_koshufile "$koshuDir\Templates\koshu.ps1" "$TestDrive\koshu.ps1" $version $packagesDir

    It "copies koshu.ps1 to target directory" {
		(test-path "$TestDrive\koshu.ps1").should.be($true)
    }
	
	It "replaces version token" {
		$content = (Get-Content "$TestDrive\koshu.ps1" | Out-String)
		$content.Contains($version).should.be($true)
    }
	
	It "replaces packages path token" {
		$content = (Get-Content "$TestDrive\koshu.ps1" | Out-String)
		$content.Contains($packagesDir).should.be($true)
	}

}