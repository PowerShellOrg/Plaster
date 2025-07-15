BeforeDiscovery {
    if ($null -eq $env:BHProjectPath) {
        $path = Join-Path -Path $PSScriptRoot -ChildPath '..\build.ps1'
        . $path -Task Build
    }
    $global:manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Get-PlasterManifestPathForCulture' {
    InModuleScope $env:BHProjectName {
        BeforeEach {
            Mock Get-Module {
                Import-Clixml $PSScriptRoot\Fixtures\ModuleList.xml
            }
        }

        It 'Returns a list of modules' {
            $extensions = Get-ModuleExtension -ModuleName "Plaster" -ModuleVersion '2.0.0' -ListAvailable
            $extensions | Should -Not -BeNullOrEmpty
            $extensions | Should -BeOfType 'PSCustomObject'
            $extensions.Count | Should -Be 3
            $extensions[0].Module | Should -Be "PSStucco"
            $extensions[1].Module | Should -Be "PSStucco"
            $extensions[2].Module | Should -Be "Sampler"
        }

        It 'Returns the latest' {
            $extensions = Get-ModuleExtension -ModuleName "Plaster" -ModuleVersion '2.0.0'
            $extensions | Should -Not -BeNullOrEmpty
            $extensions | Should -BeOfType 'PSCustomObject'
            $extensions.Count | Should -Be 2
            $extensions[0].Module | Should -Be "PSStucco"
            $extensions[1].Module | Should -Be "Sampler"
        }
    }
}
