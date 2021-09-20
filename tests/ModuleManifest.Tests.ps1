Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $env:BHPSModuleManifest
        $? | Should -Be $true
    }
}
