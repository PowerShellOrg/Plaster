<#	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
		Created on:   	4/12/2016 1:11 PM
		Created by:   	June Blender
		Organization: 	SAPIEN Technologies, Inc
		Filename:		*.Help.Tests.ps1
		===========================================================================
	.DESCRIPTION
	To test help for the commands in a module, place this file in the module folder.
	To test any module from any path, use https://github.com/juneb/PesterTDD/Module.Help.Tests.ps1
#>

<#
.SYNOPSIS
Gets command parameters; one per name. Prefers default parameter set.

.DESCRIPTION
Gets one CommandParameterInfo object for each parameter in the specified
command. If a command has more than one parameter with the same name, this
function gets the parameters in the default parameter set, if one is specified.

For example, if a command has two parameter sets:
	Name, ID  (default)
	Name, Path
This function returns:
    Name (default), ID Path

This function is used to get parameters for help and for help testing.

.PARAMETER Command
Enter a CommandInfo object, such as the object that Get-Command returns. You
can also pipe a CommandInfo object to the function.

This parameter takes a CommandInfo object, instead of a command name, so
you can use the parameters of Get-Command to specify the module and version 
of the command.

.EXAMPLE
PS C:\> Get-ParametersDefaultFirst -Command (Get-Command New-Guid)
This command uses the Command parameter to specify the command to 
Get-ParametersDefaultFirst

.EXAMPLE
PS C:\> Get-Command New-Guid | Get-ParametersDefaultFirst 
You can also pipe a CommandInfo object to Get-ParametersDefaultFirst

.EXAMPLE
PS C:\> Get-ParametersDefaultFirst -Command (Get-Command BetterCredentials\Get-Credential)
You can use the Command parameter to specify the CommandInfo object. This
command runs Get-Command module-qualified name value.

.EXAMPLE
PS C:\> $ModuleSpec = @{ModuleName='BetterCredentials';RequiredVersion=4.3}
PS C:\> Get-Command -FullyQualifiedName $ModuleSpec | Get-ParametersDefaultFirst
This command uses a Microsoft.PowerShell.Commands.ModuleSpecification object to 
specify the module and version. You can also use it to specify the module GUID.
Then, it pipes the CommandInfo object to Get-ParametersDefaultFirst.
#>
function Get-ParametersDefaultFirst {
	param (
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true)]
		[System.Management.Automation.CommandInfo]
		$Command
	)
	
	BEGIN {
		$Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable', 'Whatif', 'Confirm'
		$parameters = @()
	}

	PROCESS {
		if ($defaultPSetName = $Command.DefaultParameterSet) {
			$defaultParameters = ($Command.ParameterSets | Where-Object Name -eq $defaultPSetName).parameters | Where-Object Name -NotIn $Common
			$otherParameters = ($Command.ParameterSets | Where-Object Name -ne $defaultPSetName).parameters | Where-Object Name -NotIn $Common
			
			$parameters += $defaultParameters
			if ($parameters -and $otherParameters) {
				$otherParameters | ForEach-Object {

					if ($_.Name -notin $parameters.Name) {
						$parameters += $_
					}
				}

				$parameters = $parameters | Sort-Object Name
			}
		}

		else {
			$parameters = $Command.ParameterSets.Parameters | Where-Object Name -NotIn $Common | Sort-Object Name -Unique
		}
		
		return $parameters
	}

	END { }
}

. $PSScriptRoot\Shared.ps1
$ModuleBase = Split-Path -Parent $PSScriptRoot

if ((Split-Path $ModuleBase -Leaf) -eq 'src') {
	$ModuleBase = Split-Path $ModuleBase -Parent
}

$ModuleName = Split-Path $ModuleBase -Leaf
$commands = Get-Command -Module $ModuleName -CommandType Cmdlet, Function, Workflow  # Not alias

## When testing help, remember that help is cached at the beginning of each session.
## To test, restart session.
foreach ($command in $commands) {
	$commandName = $command.Name
	
	# The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
	$Help = Get-Help $ModuleName\$commandName -ErrorAction SilentlyContinue
	
	Describe "Test help for $commandName" {
		# If help is not found, synopsis in auto-generated help is the syntax diagram
		It "should not be auto-generated" {
			$Help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
		}
		
		# Should be a synopsis for every function
		It "gets synopsis for $commandName" {
			$Help.Synopsis | Should Not beNullOrEmpty
		}
		
		# Should be a description for every function
		It "gets description for $commandName" {
			$Help.Description | Should Not BeNullOrEmpty
		}
		
		# Should be at least one example
		It "gets example code from $commandName" {
			($Help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
		}
		
		# Should be at least one example description
		It "gets example help from $commandName" {
			($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
		}
		
		Context "Test parameter help for $commandName" {
			# Define ShouldProcess parameters for exclusion (It's pretty straightforward what these switches ought to do!).
			$ShouldProcessParameters = 'WhatIf', 'Confirm'

			# Get parameters. When >1 parameter with same name, 
			# get parameter from the default parameter set, if any.
			$parameters = Get-ParametersDefaultFirst -Command $command
			$parameterNames = $parameters.Name  | Where-Object { $_ -notin $ShouldProcessParameters }
			$HelpParameterNames = $Help.Parameters.Parameter.Name | Where-Object { $_ -notin $ShouldProcessParameters } | Sort-Object -Unique
			
			foreach ($parameter in $parameters) {
				$parameterName = $parameter.Name
				$parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName
				
				# Should be a description for every parameter
				It "gets help for parameter: $parameterName : in $commandName" {
					$parameterHelp.Description.Text | Should Not BeNullOrEmpty
				}
				
				# Required value in Help should match IsMandatory property of parameter
				It "help for $parameterName parameter in $commandName has correct Mandatory value" {
					$codeMandatory = $parameter.IsMandatory.toString()
					$parameterHelp.Required | Should Be $codeMandatory
				}
				
				# Parameter type in Help should match code
				It "help for $commandName has correct parameter type for $parameterName" {
					$codeType = $parameter.ParameterType.Name
					# To avoid calling Trim method on a null object.
					$helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
					$helpType | Should be $codeType
				}
			}
			
			foreach ($helpParm in $HelpParameterNames) {
				# Shouldn't find extra parameters in help.
				It "finds help parameter in code: $helpParm" {
					$helpParm -in $parameterNames | Should Be $true
				}
			}
		}
	}
}