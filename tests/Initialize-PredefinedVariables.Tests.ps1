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
Describe 'Initialize-PredefinedVariables' {
    InModuleScope $env:BHProjectName {
        BeforeDiscovery {
            $script:variables = @(
                'PLASTER_TemplatePath',
                'PLASTER_DestinationPath',
                'PLASTER_DestinationName',
                'PLASTER_DirSepChar',
                'PLASTER_HostName',
                'PLASTER_Version',
                'PLASTER_Guid1',
                'PLASTER_Guid2',
                'PLASTER_Guid3',
                'PLASTER_Guid4',
                'PLASTER_Guid5',
                'PLASTER_Date',
                'PLASTER_Time',
                'PLASTER_Year'
            )
            foreach ($var in $script:variables) {
                if (Get-Variable -Name $var -ErrorAction SilentlyContinue) {
                    Remove-Variable -Name $var -Scope Script
                }
            }
        }
        BeforeAll {
            $script:examplesPath = Resolve-Path "$env:BHProjectPath/examples/"
            $script:destPath = 'Test:\Destination'
            $script:output = Initialize-PredefinedVariables -TemplatePath $script:examplesPath -DestPath $script:destPath
        }
        It 'should not return any output' {
            $script:output | Should -BeNullOrEmpty
        }

        It "initializes predefined variable <_>" -ForEach $script:variables {
            $varValue = Get-Variable -Name $_ -Scope Script -ErrorAction SilentlyContinue
            $varValue | Should -Not -BeNullOrEmpty
        }

        It 'PLASTER_TemplatePath should match the provided template path' {
            $expectedPath = ($script:examplesPath).ToString().TrimEnd('\', '/')
            $actualPath = (Get-Variable -Name 'PLASTER_TemplatePath' -Scope Script).Value
            $actualPath | Should -Be $expectedPath
        }

        It 'PLASTER_DestinationPath should match the provided destination path' {
            $expectedPath = ($script:destPath).ToString().TrimEnd('\', '/')
            $actualPath = (Get-Variable -Name 'PLASTER_DestinationPath' -Scope Script).Value
            $actualPath | Should -Be $expectedPath
        }
    }
}
