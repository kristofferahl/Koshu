nuget install Pester -Version 2.0.3 -OutputDirectory "Source\Packages"

$pesterDir = ".\Source\Packages\Pester.2.0.3\tools"
Import-Module "$pesterDir\Pester.psm1";
Invoke-Pester .\Source\Specifications\*
