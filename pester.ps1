$pesterVersion = '3.4.0'
$nuget = (resolve-path '.\.nuget\nuget.exe')

& $nuget install Pester -Version $pesterVersion -OutputDirectory "Source\packages"

rmdir 'Build\Temp' -recurse -force -erroraction silentlycontinue | out-null
mkdir 'Build\Temp' -force | out-null
& $nuget pack 'Source\Koshu.nuspec' -Version 0.0.1 -OutputDirectory "Build\Temp" -NoPackageAnalysis

Import-Module ".\Source\packages\Pester.$pesterVersion\tools\Pester.psm1"
Invoke-Pester '.\Source\Specifications\*'
