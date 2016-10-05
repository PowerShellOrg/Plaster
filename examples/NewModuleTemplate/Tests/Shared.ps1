$ModuleManifestName = '<%=$PLASTER_PARAM_ModuleName%>.psd1'
$ModulePath         = "$PSScriptRoot\..\src\$ModuleManifestName"

# -Scope Global is needed when running tests from inside of psake, otherwise
# the module's functions cannot be found in the Plaster\ namespace
Import-Module $ModulePath -Scope Global