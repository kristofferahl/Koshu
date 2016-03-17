# Koshu

The honey flavoured psake task automation tool

[![Build status](https://ci.appveyor.com/api/projects/status/verrum69shmd1kj5?svg=true)](https://ci.appveyor.com/project/kristofferahl/koshu)
[![Gitter](https://badges.gitter.im/kristofferahl/Koshu.svg)](https://gitter.im/kristofferahl/Koshu?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## Installing Koshu

Open up a command line and enter the following command:

	powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.github.com/kristofferahl/Koshu/develop/install.ps1'))"

This will create a file called koshu.ps1 in the current directory. This file enables you to invoke tasks as well as do scaffolding of task files and plugins.

**Note nuget must be in your path or located in a subdirectory of the current directory.**

## Initializing Koshu

In powershell, enter the path to the koshu.ps1 file and invoke it with the switch -load.

	<directoryPath>\koshu.ps1 -load

## Scaffolding a taskfile

Scaffolding a taskfile is as easy as calling Koshu-Scaffold passing a single parameter (-template)

	Koshu-Scaffold -template <templateName>

## Running Koshu

### Powershell

	.\koshu [<target>] [<taskFile>]

#### Powershell examples

	.\koshu
	.\koshu compile
	.\koshu -taskfile build.ps1
	.\koshu compile build.ps1

### Command line

	powershell .\koshu [<target>] [<taskFile>]

#### Command line examples

	powershell .\koshu
	powershell .\koshu compile
	powershell .\koshu -taskfile build.ps1
	powershell .\koshu compile build.ps1

### Bash

	powershell koshu [<target>] [<taskFile>]

#### Bash examples

	powershell koshu
	powershell koshu compile
	powershell koshu -taskfile build.ps1
	powershell koshu compile build.ps1

### Using koshu.cmd or <taskfile>.cmd

#### From explorer

	Simply double click .cmd to run

#### From command line

	koshu
	koshu compile
	koshu compile build.ps1

## Plugins

Koshu can easily be extended through plugin packages. Plugin packages is simply a neat way for you to package up reusable powershell scripts and modules.

A plugin is usually a nuget package containing a powershell module that you want to import and use when running tasks. Packages can also be defined as git repositories or directories on a file share. You can read more on how to create a plugin here: https://github.com/kristofferahl/Koshu.PluginTemplate

### Using plugin packages

Simply add a packages section at the top of your task file and specify the plugins you want to use.

	packages @{
	    "NugetPackageId"=""
	}

Some plugin packages supports the Koshu configuration model. It will give you a chance to change default values before running tasks.

	config @{
		"PackageName"=@{}
	}

Have a look at the plugins homepage to find out what configuration options that are available.

#### NuGet package plugins

	packages @{
		# Unspecified version
	    "NugetPackageId"=""

	    # Specific version
	    "NugetPackageId"=""
	}

#### Git repository plugins

	packages @{
		"PluginName"="git+file:///C/SomeDirectory/KoshuPluginRepository"
		"PluginName"="git+file:///C/SomeDirectory/KoshuPluginRepository#branch"
		"PluginName"="git+file:///C/SomeDirectory/KoshuPluginRepository#tag"
		"PluginName"="git+file:///C/SomeDirectory/KoshuPluginRepository#sha"

		"PluginName"="git+https://github.com/username/koshu-plugin.git"
		"PluginName"="git+https://github.com/username/koshu-plugin.git#branch"
		"PluginName"="git+https://github.com/username/koshu-plugin.git#tag"
		"PluginName"="git+https://github.com/username/koshu-plugin.git#sha"
	}

#### Directory plugins

	packages @{
		"PluginName"="dir+C:\SomeDirectory" # Looks for a plugin at C:\SomeDirectory\PluginName
	}

## Plugins on Nuget

https://www.nuget.org/packages?q=Tags%3A%22koshu%22

## Pack task

Before you can call pack_solution you need to make sure that the project (csproj) file you want to pack has imported the Microsoft.WebApplication.targets file.
Next you add a Publish task that depends on PipelinePreDeployCopyAllFilesToOneFolder.

	<Target Name="Publish" DependsOnTargets="PipelinePreDeployCopyAllFilesToOneFolder" />
