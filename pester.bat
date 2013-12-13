nuget install Pester -Version 2.0.3 -OutputDirectory "Source\Packages"

@echo off
SET DIR=%~dp0%
SET ARGS=%*
SET PESTERDIR="%~dp0%\Source\Packages\Pester.2.0.3\tools"
if NOT '%1'=='' SET ARGS=%ARGS:"=\"%
if '%1'=='/?' goto usage
if '%1'=='-?' goto usage
if '%1'=='?' goto usage
if '%1'=='/help' goto usage
if '%1'=='help' goto usage
if '%1'=='new-fixture' goto newfixture

@PowerShell -NonInteractive -NoProfile -ExecutionPolicy unrestricted -Command ^
 "& Import-Module '%PESTERDIR%\Pester.psm1'; & { Invoke-Pester .\Source\Specifications\* -EnableExit %ARGS%}"

goto finish
:newfixture
SHIFT
@PowerShell -NonInteractive -NoProfile -ExecutionPolicy unrestricted -Command ^
 Import-Module '%PESTERDIR%..\Pester.psm1'; New-Fixture %* 

goto finish
:usage
if NOT '%2'=='' goto help

echo To run pester for tests, just call pester or runtests with no arguments
echo Example: pester
echo To create an auomated test, call pester new-fixture with path and name
echo Example: pester new-fixture [-Path relativePath] -Name nameOfTestFile
echo For Detailed help information, call pester help with a help topic. See help topic about_Pester for a list of all topics at the end
echo Example: pester help about_Pester
goto finish

:help
@PowerShell -NonInteractive -NoProfile -ExecutionPolicy unrestricted -Command "& Import-Module '%DIR%..\Pester.psm1'; & { Get-Help %2}"

:finish
exit /B %errorlevel%