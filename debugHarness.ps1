# Debug unit tests
# Invoke-Pester $PSScriptRoot\..\test
# return

# Use this file to debug the module.
Import-Module $PSScriptRoot\src\Plaster.psd1

$OutDir = "$PSScriptRoot\examples\Out"
Remove-Item $OutDir -Recurse -ErrorAction SilentlyContinue

$PlasterParams = @{
    TemplatePath = "$PSScriptRoot\src\Templates\NewModule"
    DestinationPath = $OutDir
    ModuleName = 'FooUtils'
    ModuleDesc = 'Utilities for Foo.'
    FullName = 'John Q. Doe'
    Version = '1.2.0'
    Options = 'Git','psake','Pester','platyPS'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
