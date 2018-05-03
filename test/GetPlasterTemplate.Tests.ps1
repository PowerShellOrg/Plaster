. $PSScriptRoot\Shared.ps1

Describe 'Get-PlasterTemplate' {
    $examplesPath = Resolve-Path "$PSScriptRoot/../examples/"

    Context "when given a path" {
        It "finds the contained template" {
            $templates = Get-PlasterTemplate -Path "$examplesPath/NewModule"
            $templates[0].Title | Should -Be "New Module"
        }

        It "finds templates recursively" {
            $templates = Get-PlasterTemplate -Path "$PSScriptRoot/../examples/" -Recurse
            $templates[0].Title | Should -Be "New DSC Resource Script File"
        }

        It "finds templates recursively and by name" {
            $template = Get-PlasterTemplate -Path "$PSScriptRoot/../examples/" -Recurse -Name 'NewDscResourceScript*'
            $template.Name | Should -Be "NewDscResourceScriptFile"
        }

        It "finds templates recursively and by tag" {
            $template = Get-PlasterTemplate -Path "$PSScriptRoot/../examples/" -Recurse -Tag 'DSC'
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
            $env:PSModulePath = "$(Resolve-Path "$PSScriptRoot/../examples")$([System.IO.Path]::PathSeparator)$($env:PSModulePath)";

            $templates = Get-PlasterTemplate -IncludeInstalledModules
            $templates.Count -gt $builtInTemplates.Count | Should -Be $true
            $templates[$builtInTemplates.Count].Title | Should -Be "TemplateOne Template"

            $env:PSModulePath = $oldPSModulePath
        }
    }
}