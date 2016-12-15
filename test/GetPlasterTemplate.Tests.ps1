. $PSScriptRoot\Shared.ps1

Describe 'Get-PlasterTemplate' {
    $examplesPath = Resolve-Path "$PSScriptRoot/../examples/"

    Context "when given a path" {
        It "finds the contained template" {
            $templates = Get-PlasterTemplate -Path "$examplesPath/NewModule"
            $templates[0].Title | Should Be "New Module"
        }

        It "finds templates recursively" {
            $templates = Get-PlasterTemplate -Path "$PSScriptRoot/../examples/" -Recurse
            $templates[0].Title | Should Be "New DSC Resource Script File"
        }
    }

    Context "when searching modules for templates" {
        It "finds built-in templates" {
            $templates = Get-PlasterTemplate
            $templates[0].Title | Should Be "New PowerShell Manifest Module"
        }

        It "finds templates included with modules" {
            $oldPSModulePath = $env:PSModulePath;
            $env:PSModulePath = "$(Resolve-Path "$PSScriptRoot/../examples")$([System.IO.Path]::PathSeparator)$($env:PSModulePath)";

            $templates = Get-PlasterTemplate -IncludeInstalledModules
            $templates[1].Title | Should Be "TemplateOne Template"

            $env:PSModulePath = $oldPSModulePath
        }
    }
}