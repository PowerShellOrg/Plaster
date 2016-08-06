# Use this file to debug the module.
Import-Module $PSScriptRoot\..\src\Plaster.psd1

$OutDir = "$PSScriptRoot\Out"
Remove-Item $OutDir -Recurse -ErrorAction SilentlyContinue
New-Item $OutDir -ItemType Directory -ErrorAction SilentlyContinue > $null

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
