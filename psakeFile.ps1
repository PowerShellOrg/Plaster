Properties {
  # Set this to $true to create a module with a monolithic PSM1
  $PSBPreference.Build.CompileModule = $True
  $PSBPreference.Build.CompileHeader = @'
#Requires -Version 5.1
using namespace System.Management.Automation

# Module initialization
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

'@
  $PSBPreference.Help.DefaultLocale = 'en-US'
  $PSBPreference.Test.OutputFile = 'out/testResults.xml'
  $PSBPreference.Build.CopyDirectories = @('en-US', 'Schema', 'Templates')
}

Task Default -Depends Test

Task Test -FromModule PowerShellBuild -MinimumVersion '0.6.1'
