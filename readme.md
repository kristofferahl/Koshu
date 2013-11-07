# Koshu

The honey flavoured psake build automation tool

## Installing Koshu

Open up powershell and enter the following command:

	nuget install koshu -outputdirectory <packagesDirectoryPath>

## Initializing Koshu

In powershell, enter the path to the init.ps1 file located in the Koshu nuget package.

	<koshuPackageDirectoryPath>\tools\init.ps1

## Scaffolding a buildscript

Scaffolding a build is as easy as calling Koshu-Scaffold passing a single parameter (-template)

	Koshu-Scaffold -template <templateName>

## Running a Koshu build

### Powershell

	.\koshu <buildFile> [<target>]
	
### Command line

	powershell .\koshu <buildFile> [<target>]
	
### Bash

	powershell koshu <buildFile> [<target>]
	
## Pack task

Before you can call pack_solution you need to make sure that the project (csproj) file you want to pack has imported the Microsoft.WebApplication.targets file.
Next you add a Publish task that depends on PipelinePreDeployCopyAllFilesToOneFolder.

	<Target Name="Publish" DependsOnTargets="PipelinePreDeployCopyAllFilesToOneFolder" />
