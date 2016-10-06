. $PSScriptRoot\Shared.ps1

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\src\$ModuleManifestName
        $? | Should Be $true
    }
}
