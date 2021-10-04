BeforeDiscovery {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Get-PlasterTemplate' {
    BeforeEach {
        $examplesPath = Resolve-Path "$env:BHProjectPath/examples/"
    }

    Context "when given a path" {
        It "finds the contained template" {
            $templates = Get-PlasterTemplate -Path "$examplesPath/NewModule"
            $templates[0].Title | Should -Be "New Module"
        }

        It "finds templates recursively" {
            $templates = Get-PlasterTemplate -Path $examplesPath -Recurse
            $templates[0].Title | Should -Be "New DSC Resource Script File"
        }

        It "finds templates recursively and by name" {
            $template = Get-PlasterTemplate -Path $examplesPath -Recurse -Name 'NewDscResourceScript*'
            $template.Name | Should -Be "NewDscResourceScriptFile"
        }

        It "finds templates recursively and by tag" {
            $template = Get-PlasterTemplate -Path $examplesPath -Recurse -Tag 'DSC'
            $template.Name | Should -Be "NewDscResourceScriptFile"
        }
    }

    Context "when searching modules for templates" {
        It "finds built-in templates" {
            $templates = Get-PlasterTemplate
            $templates | Where-Object Title -eq 'New PowerShell Manifest Module' | Should -Not -BeNullOrEmpty
        }

        It "finds built-in templates by name" {
            $template = Get-PlasterTemplate -Name 'NewPowerShellScriptModule'
            $template.Name | Should -Be 'NewPowerShellScriptModule'
        }

        It "finds built-in templates by tag" {
            $template = Get-PlasterTemplate -Tag 'Module'
            $template.Name | Should -Be 'NewPowerShellScriptModule'
        }

        It "finds templates included with modules" {
            $builtInTemplates = Get-PlasterTemplate
            $oldPSModulePath = $env:PSModulePath;
            # Only use example path, because tester could have many templates
            # installed and ordering is Alphbetical.
            $env:PSModulePath = $examplesPath;

            $templates = Get-PlasterTemplate -IncludeInstalledModules
            $templates.Count -gt $builtInTemplates.Count | Should -Be $true
            $templates[$builtInTemplates.Count].Title | Should -Be "TemplateOne Template"

            $env:PSModulePath = $oldPSModulePath
        }
    }
}