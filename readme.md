# Koshu

The honey flavoured psake build automation tool

## Installing Koshu

Open up a command line and enter the following command:

	powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.github.com/kristofferahl/Koshu/develop/install.ps1'))"

This will create a file called koshu.ps1 in the current directory. This file enables you to invoke tasks as well as do scaffolding of task files and plugins.

## Initializing Koshu

In powershell, enter the path to the koshu.ps1 file and invoke it with the switch -load.

	<directoryPath>\koshu.ps1 -load

## Scaffolding a buildscript

Scaffolding a build is as easy as calling Koshu-Scaffold passing a single parameter (-template)

	Koshu-Scaffold -template <templateName>

## Running a Koshu build

### Powershell

	.\koshu <taskFile> [<target>]
	
### Command line

	powershell .\koshu <taskFile> [<target>]
	
### Bash

	powershell koshu <taskFile> [<target>]
	
## Pack task

Before you can call pack_solution you need to make sure that the project (csproj) file you want to pack has imported the Microsoft.WebApplication.targets file.
Next you add a Publish task that depends on PipelinePreDeployCopyAllFilesToOneFolder.

	<Target Name="Publish" DependsOnTargets="PipelinePreDeployCopyAllFilesToOneFolder" />
