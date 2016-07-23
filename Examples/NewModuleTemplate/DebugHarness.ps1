# Use this file to debug the module.
Import-Module $PSScriptRoot\..\..\Plaster.psd1

#Import-Module Pester
#Invoke-Pester $PSScriptRoot\..\..\Tests\ExpandFileSourceSpec.Tests.ps1

Remove-Item $PSScriptRoot\..\Out -Recurse
New-Item $PSScriptRoot\..\Out -ItemType Directory > $null

$PlasterParams = @{
    TemplatePath = $PWD
    Destination = '..\Out'
    ModuleName = 'FooUtils'
    FullName = 'John Q. Doe'
    Email = 'john.q.doe@outlook.com'
    Version = '1.2.0'
    Options = 'Git','PSake','Pester'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
