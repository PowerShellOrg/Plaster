# Use this file to debug the module.
if ($null -eq $env:BHProjectPath) {
    $path = Join-Path -Path $PSScriptRoot -ChildPath '..\build.ps1'
    . $path -Task Build
}
$manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
$outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
$outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
$outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
$outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop

#region Setup Output Directory
$OutDir = Join-Path $outputDir "\HarnessOutput"
Remove-Item $OutDir -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $OutDir | Out-Null
#endregion Setup Output Directory

# Various debug scenarios other than running Invoke-Plaster.
# Invoke-Pester $PSScriptRoot\test
# Test-PlasterManifest "$PSScriptRoot\src\Templates\NewModule\plasterManifest.xml" -Verbose
# Invoke-psake $PSScriptRoot\build.psake.ps1 -taskList BuildHelp
# return

# $PlasterParams = @{
#     TemplatePath = "$PSScriptRoot\src\Templates\AddPSScriptAnalyzerSettings"
#     DestinationPath = $OutDir
#     FileName = 'PSScriptAnalyzerSettings.psd1'
#     Editor = 'VSCode'
#     PassThru = $true
# }

$PlasterParams = @{
    TemplatePath = "$PSScriptRoot\Plaster\Templates\NewPowerShellScriptModule"
    DestinationPath = $OutDir
    ModuleName = 'FooUtils'
    Version = '1.2.0'
    Editor = 'VSCode'
    PassThru = $true
}

# $PlasterParams = @{
#     TemplatePath = "$PSScriptRoot\examples\NewDscResourceScript"
#     DestinationPath = $OutDir
#     TargetResourceName = 'ZipFile'
#     Ensure = 'Yes'
#     PassThru = $true
# }

# $PlasterParams = @{
#     TemplatePath = "$PSScriptRoot\examples\NewModule"
#     DestinationPath = $OutDir
#     ModuleName = 'FooUtils'
#     ModuleDesc = 'Utilities for Foo.'
#     FullName = 'John Q. Doe'
#     Version = '1.2.0'
#     Options = 'Git','psake','Pester','PSScriptAnalyzer','platyPS'
#     Editor = 'VSCode'
#     License = 'MIT'
#     PassThru = $true
# }

$obj = Invoke-Plaster @PlasterParams -WhatIf

"PassThru object is:"
$obj
