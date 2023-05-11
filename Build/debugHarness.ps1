# Use this file to debug the module.
Import-Module $PSScriptRoot\src\Plaster.psd1

# Various debug scenarios other than running Invoke-Plaster.
# Invoke-Pester $PSScriptRoot\test
# Test-PlasterManifest "$PSScriptRoot\src\Templates\NewModule\plasterManifest.xml" -Verbose
# Invoke-psake $PSScriptRoot\build.psake.ps1 -taskList BuildHelp
# return

$OutDir = "$PSScriptRoot\examples\Out"
Remove-Item $OutDir -Recurse -ErrorAction SilentlyContinue

# $PlasterParams = @{
#     TemplatePath = "$PSScriptRoot\src\Templates\AddPSScriptAnalyzerSettings"
#     DestinationPath = $OutDir
#     FileName = 'PSScriptAnalyzerSettings.psd1'
#     Editor = 'VSCode'
#     PassThru = $true
# }

$PlasterParams = @{
    TemplatePath = "$PSScriptRoot\src\Templates\NewPowerShellScriptModule"
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

$obj = Invoke-Plaster @PlasterParams -Force

"PassThru object is:"
$obj
