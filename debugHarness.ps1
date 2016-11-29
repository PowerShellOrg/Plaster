# Use this file to debug the module.
Import-Module $PSScriptRoot\src\Plaster.psd1

# Various debug scenarios other than running Invoke-Plaster.
# Invoke-Pester $PSScriptRoot\test
# Test-PlasterManifest "$PSScriptRoot\src\Templates\NewModule\plasterManifest.xml" -Verbose
# Invoke-psake $PSScriptRoot\build.psake.ps1 -taskList BuildHelp
# return

$OutDir = "$PSScriptRoot\examples\Out"
Remove-Item $OutDir -Recurse -ErrorAction SilentlyContinue

$PlasterParams = @{
    TemplatePath = "$PSScriptRoot\examples\NewModule"
    DestinationPath = $OutDir
    ModuleName = 'FooUtils'
    ModuleDesc = 'Utilities for Foo.'
    FullName = 'John Q. Doe'
    Version = '1.2.0'
    Options = 'Git','psake','Pester','PSScriptAnalyzer','platyPS'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
