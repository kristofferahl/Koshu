# Koshu

The honey flavoured psake build automation tool

## Running a Koshu build

### Powershell

	.\koshu <buildFile> <target>
	
### Command line

	powershell .\koshu <buildFile> <target>
	
### Bash

	powershell koshu <buildFile> <target>
	
## Pack task

Before you can call pack_solution you need to make sure that the project (csproj) file you want to pack has imported the Microsoft.WebApplication.targets file.
Next you add a Publish task that depends on PipelinePreDeployCopyAllFilesToOneFolder.

	<Target Name="Publish" DependsOnTargets="PipelinePreDeployCopyAllFilesToOneFolder" />
