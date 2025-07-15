BeforeDiscovery {
    if ($null -eq $env:BHProjectPath) {
        $path = Join-Path -Path $PSScriptRoot -ChildPath '..\build.ps1'
        . $path -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Resolve-ModuleVersionString' {
    InModuleScope $env:BHProjectName {
        It 'Should resolve a valid version string' {
            $versionString = "1.2.3"
            $result = Resolve-ModuleVersionString -versionString $versionString
            $result | Should -BeOfType [System.Management.Automation.SemanticVersion]
            $result.ToString() | Should -Be $versionString
        }

        It 'Should append .0 to a version string with only two components' {
            $versionString = "1.2"
            $result = Resolve-ModuleVersionString -versionString $versionString
            $result | Should -BeOfType [System.Management.Automation.SemanticVersion]
            $result.ToString() | Should -Be "1.2.0"
        }

        It 'Should handle invalid version strings gracefully' {
            $versionString = "invalid.version"
            { Resolve-ModuleVersionString -versionString $versionString } | Should -Throw
        }
    }
}
