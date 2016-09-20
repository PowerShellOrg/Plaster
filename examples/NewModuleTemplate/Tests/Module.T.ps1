$ModuleManifestName = '<%=$PLASTER_PARAM_ModuleName%>.psd1'
# <%=${PLASTER_GUID1}%> - testing use of PLASTER predefined variables.
Import-Module $PSScriptRoot\..\src\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\src\$ModuleManifestName
        $? | Should Be $true
    }
}
