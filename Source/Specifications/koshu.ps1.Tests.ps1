$here			= Split-Path -Parent $MyInvocation.MyCommand.Path
$koshuDir		= "$here\..\Koshu"

. "$koshuDir\koshu-helpers.ps1"

Describe "koshu.ps1" {

	$source			= "$koshuDir\Templates\koshu.ps1"
	$destination	= "$TestDrive\koshu.ps1"
	$version		= "0.3.0"
	$packagesDir	= ".\Source\Packages"

	Context "when nuget is not in the path" {

		if ($env:Path.Contains("c:\Nuget-Console\;") -eq $true) {
			Write-Host "Removing nuget from path" -Fore yellow
			$env:Path = $env:Path.Replace("c:\Nuget-Console\;","")
		}
		
		scaffold_koshufile $source $destination $version $packagesDir
		Set-Content -Value "properties {}; task default -depends doit; task doit {};" -Path "$TestDrive\build.ps1"
		
		$currentDir = Get-Location
		Set-Location $TestDrive
		
		$message = ""
		try {
			.$destination build doit
		} catch  [Exception] {
			$message = $_.Exception.Message
		}
		
		Set-Location $currentDir
        
		It "promts user to add nuget to path" {
			$message.should.be("Nuget.exe is not in your path! Add it to your environment variables.")
		}
		
    }
	
	Context "when nuget is in the path" {
	
		if ($env:Path.Contains("c:\Nuget-Console\;") -eq $false) {
			Write-Host "Adding nuget to path" -Fore yellow
			$env:Path = $env:Path.TrimEnd(';')
			$env:Path = $env:Path + ";c:\Nuget-Console\;"
		}
		
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