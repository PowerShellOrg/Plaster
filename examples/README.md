# Plaster Examples

## NewModuleTemplate
This example demonstrates a template used for scaffolding a new module project.  It has
support for Git, PSake build script, Pester tests.

To run this example, cd to the NewModuleTemplate folder and execute:
```powershell
Import-Module ..\..\src\Plaster.psd1
Invoke-Plaster -TemplatePath . -Destination ..\Out
```
This will prompt you for the template's required parameters as defined in plasterManifest.xml.  If you
run the Invoke-Plaster command a second time, you see Plaster's file conflict handling.  You can use
the `-Force` parameter to automatically overwrite existing files.

You can bypass the interactive prompting by providing the necessary parameters directly to Invoke-Plaster as
demonstrated below.  Note: you will get autocompletion support for template parameters as they are added
as dynamic parameters to Invoke-Plaster.
```powershell
$PlasterParams = @{
    TemplatePath = $PWD
    Destination = '..\Out'
    ModuleName = 'FooUtils'
    ModuleDesc = 'Commands for Foo'
    FullName = 'John Q. Doe'
    Email = 'john.q.doe@example.org'
    Version = '1.2.0'
    Options = 'Git','PSake','Pester'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
```