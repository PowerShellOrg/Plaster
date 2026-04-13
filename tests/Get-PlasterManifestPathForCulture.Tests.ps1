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
Describe 'Get-PlasterManifestPathForCulture' {
  BeforeEach {
    $script:examplesPath = Resolve-Path "$env:BHProjectPath/examples/"
  }

  Context "when given a template path and culture" {
    InModuleScope $env:BHProjectName {
      It "returns the manifest for the specified culture" {
        $culture = Get-Culture -name "en-US"
        $plasterManifestFilename = "plasterManifest_en-US.xml"
        Mock -CommandName 'Test-Path' -MockWith { $true } -ParameterFilter { $Path -like "*$($script:examplesPath)" }
        $manifestPath = Get-PlasterManifestPathForCulture -TemplatePath $script:examplesPath -Culture $culture
        $manifestPath | Should -BeLike "*$($plasterManifestFilename)"
      }

      It "returns the parent culture manifest if available" {
        $culture = New-Object System.Globalization.CultureInfo("fr-FR")
        $plasterManifestFilename = "plasterManifest_fr-FR.xml"

        Mock -CommandName 'Test-Path' -MockWith { $False } -ParameterFilter { $Path -like "*en-US*" }
        Mock -CommandName 'Test-Path' -MockWith { $True } -ParameterFilter { $Path -like "*fr-FR*" }

        $manifestPath = Get-PlasterManifestPathForCulture -TemplatePath $script:examplesPath -Culture $culture
        $manifestPath | Should -BeLike "*$($plasterManifestFilename)"
      }

      It "falls back to invariant culture manifest if no specific match is found" {
        $culture = New-Object System.Globalization.CultureInfo("xx-XX")
        Mock -CommandName 'Test-Path' -MockWith { $False } -ParameterFilter { $Path -like "*en-US*" }
        Mock -CommandName 'Test-Path' -MockWith { $True } -ParameterFilter { $Path -like "*fr-FR*" }
        Mock -CommandName 'Test-Path' -MockWith { $True } -ParameterFilter { $Path -like "*plasterManifest.xml" }
        $manifestPath = Get-PlasterManifestPathForCulture -TemplatePath $script:examplesPath -Culture $culture
        $manifestPath | Should -BeLike "*plasterManifest.xml"
      }
    }
  }
}
