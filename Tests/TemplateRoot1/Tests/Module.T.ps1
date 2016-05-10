$ModuleManifestName = '<%=$($Parameters.ModuleName)%>.psd1'
# <%=${PLASTER_GUID1}%> - testing use of PLASTER predefined variables.
Import-Module $PSScriptRoot\..\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}
