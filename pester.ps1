nuget install Pester -Version 2.0.3 -OutputDirectory "Source\packages"

rmdir "Build\Temp" -recurse -force -erroraction silentlycontinue | out-null
mkdir "Build\Temp" -force | out-null
nuget pack "Source\Koshu.nuspec" -Version 0.0.1 -OutputDirectory "Build\Temp"

$pesterDir = ".\Source\packages\Pester.2.0.3\tools"
Import-Module "$pesterDir\Pester.psm1";

start-sleep -seconds 1

clear

Invoke-Pester .\Source\Specifications\*
