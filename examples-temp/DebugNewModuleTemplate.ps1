# Use this file to debug the module.
Import-Module $PSScriptRoot\..\src\Plaster.psd1

Remove-Item $PSScriptRoot\Out -Recurse
New-Item $PSScriptRoot\Out -ItemType Directory > $null

$PlasterParams = @{
    TemplatePath = "$PSScriptRoot\NewModuleTemplate"
    Destination = '.\Out'
    ModuleName = 'FooUtils'
    ModuleDesc = 'Utilities for Foo.'
    FullName = 'John Q. Doe'
    Email = 'john.q.doe@outlook.com'
    Version = '1.2.0'
    Options = 'Git','PSake','Pester'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
