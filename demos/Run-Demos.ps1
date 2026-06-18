<#
.SYNOPSIS
    Runs the Plaster presentation demos non-interactively.
.DESCRIPTION
    Imports Plaster from source and scaffolds three projects into demos/output:
      1. XML manifest  - classic greeter script
      2. JSON manifest - same greeter, modern format
      3. JSON manifest - full-featured module (multichoice, conditions, modify, newModuleManifest)

    Non-interactive: every template parameter is passed on the command line, so
    nothing prompts. Great for a reliable live run. To demo the INTERACTIVE
    experience instead, run one template by hand, e.g.:

        Invoke-Plaster -TemplatePath .\demos\templates\02-json-greeter `
                       -DestinationPath .\demos\output\greeter-interactive
.PARAMETER Demo
    Which demo(s) to run: 1, 2, 3, or All (default).
#>
[CmdletBinding()]
param(
    [ValidateSet('1', '2', '3', '4', 'All')]
    [string]$Demo = 'All'
)

$ErrorActionPreference = 'Stop'
$root      = Split-Path $PSScriptRoot -Parent
$outputDir = Join-Path $PSScriptRoot 'output'
$templates = Join-Path $PSScriptRoot 'templates'

$moduleToLoad = Join-Path $root 'Plaster\Plaster.psd1'
Write-Host "Loading Plaster from: $moduleToLoad" -ForegroundColor DarkGray
Import-Module $moduleToLoad -Force

# Fresh output folder each run
if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
New-Item $outputDir -ItemType Directory | Out-Null

function Show-Tree($Path) {
    Get-ChildItem $Path -Recurse -File |
        ForEach-Object { '   ' + $_.FullName.Substring($Path.Length + 1) } |
        Sort-Object
}

function Write-Header($Text) {
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor DarkBlue
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host ('=' * 70) -ForegroundColor DarkBlue
}

if ($Demo -in '1', 'All') {
    Write-Header 'DEMO 1  -  XML manifest  (classic greeter script)'
    $dst = Join-Path $outputDir '01-xml-greeter'
    Invoke-Plaster -TemplatePath (Join-Path $templates '01-xml-greeter') `
                   -DestinationPath $dst -NoLogo `
                   -ScriptName 'Greet-Contoso' -Greeting 'Howdy'
    Write-Host "`n   Files created:" -ForegroundColor Green
    Show-Tree $dst
    Write-Host "`n   --- Greet-Contoso.ps1 ---" -ForegroundColor DarkGray
    Get-Content (Join-Path $dst 'Greet-Contoso.ps1') | ForEach-Object { "   $_" }
}

if ($Demo -in '2', 'All') {
    Write-Header 'DEMO 2  -  JSON manifest  (same greeter, modern format)'
    $dst = Join-Path $outputDir '02-json-greeter'
    Invoke-Plaster -TemplatePath (Join-Path $templates '02-json-greeter') `
                   -DestinationPath $dst -NoLogo `
                   -ScriptName 'Greet-Fabrikam' -Greeting 'Salutations'
    Write-Host "`n   Files created:" -ForegroundColor Green
    Show-Tree $dst
    Write-Host "`n   --- Greet-Fabrikam.ps1 ---" -ForegroundColor DarkGray
    Get-Content (Join-Path $dst 'Greet-Fabrikam.ps1') | ForEach-Object { "   $_" }
}

if ($Demo -in '3', 'All') {
    Write-Header 'DEMO 3  -  JSON manifest  (full module: multichoice + conditions + modify)'
    $dst = Join-Path $outputDir '03-json-module'
    # Features is multichoice -> pass an array. Drop 'Build' to show a condition
    # excluding a file (no build.ps1 is generated).
    Invoke-Plaster -TemplatePath (Join-Path $templates '03-json-module') `
                   -DestinationPath $dst -NoLogo `
                   -ModuleName 'AcmeWidget' -Author 'Ada Lovelace' `
                   -License 'Apache' -Features 'Pester', 'Git'
    Write-Host "`n   Files created (note: build.ps1 was skipped by condition):" -ForegroundColor Green
    Show-Tree $dst
    Write-Host "`n   --- AcmeWidget/README.md  (note __LICENSE__ was replaced) ---" -ForegroundColor DarkGray
    Get-Content (Join-Path $dst 'AcmeWidget\README.md') | ForEach-Object { "   $_" }
}

if ($Demo -in '4', 'All') {
    # Demo 4 (discovery + authoring) lives in its own script because it drives the
    # surrounding cmdlets rather than scaffolding from a fixed template.
    & (Join-Path $PSScriptRoot 'Demo4-Discovery-Authoring.ps1')
}

Write-Host "`nAll done. Output is in: $outputDir`n" -ForegroundColor Cyan
