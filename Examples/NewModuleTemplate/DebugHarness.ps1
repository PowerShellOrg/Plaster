# Use this file to debug the module.
Import-Module ..\..\Plaster.psd1

Remove-Item ..\Out -Recurse
New-Item ..\Out -ItemType Directory > $null

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
