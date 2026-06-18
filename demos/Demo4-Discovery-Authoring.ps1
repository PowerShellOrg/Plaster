<#
.SYNOPSIS
    Demo 4 - Template discovery and live manifest authoring.
.DESCRIPTION
    Shows the three "meta" cmdlets that surround Invoke-Plaster:
      * Get-PlasterTemplate  - discover templates (bundled + your own folders)
      * New-PlasterManifest  - author a brand-new JSON manifest from a folder of files
      * Test-PlasterManifest - validate a manifest before you ship it

    Ends by scaffolding from the template it just authored, proving the round-trip.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root      = Split-Path $PSScriptRoot -Parent
$templates = Join-Path $PSScriptRoot 'templates'
$outputDir = Join-Path $PSScriptRoot 'output'

Import-Module (Join-Path $root 'Plaster\Plaster.psd1') -Force

function Write-Header($Text) {
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor DarkBlue
    Write-Host "  $Text" -ForegroundColor Yellow
    Write-Host ('=' * 70) -ForegroundColor DarkBlue
}

# ----------------------------------------------------------------------------
Write-Header 'DEMO 4a  -  Discover templates with Get-PlasterTemplate'

Write-Host "`n   Templates that ship with Plaster:" -ForegroundColor Green
Get-PlasterTemplate | Format-Table Name, Version, Title -AutoSize

Write-Host "   Your own templates (any folder, -Recurse):" -ForegroundColor Green
Get-PlasterTemplate -Path $templates -Recurse | Format-Table Name, Version, Title, Tags -AutoSize

# ----------------------------------------------------------------------------
Write-Header 'DEMO 4b  -  Author a new manifest with New-PlasterManifest'

# Start from a folder that already has some files we want to template.
$scratch = Join-Path $outputDir 'authored-template'
if (Test-Path $scratch) { Remove-Item $scratch -Recurse -Force }
New-Item $scratch -ItemType Directory | Out-Null
'Write-Host "Hello from <%= $PLASTER_PARAM_Thing %>"' | Set-Content (Join-Path $scratch 'thing.ps1')
'# Notes about <%= $PLASTER_PARAM_Thing %>'          | Set-Content (Join-Path $scratch 'NOTES.md')

Write-Host "`n   Generating plasterManifest.json (-AddContent scans the folder)..." -ForegroundColor Green
New-PlasterManifest -Path (Join-Path $scratch 'plasterManifest.json') `
    -TemplateName 'MyTinyTemplate' -TemplateType Item `
    -Title 'My Tiny Template' -Description 'Authored live on stage' `
    -Author 'Grace Hopper' -Tags Demo, Authoring -AddContent

Write-Host "   --- authored plasterManifest.json ---" -ForegroundColor DarkGray
Get-Content (Join-Path $scratch 'plasterManifest.json') | ForEach-Object { "   $_" }

# ----------------------------------------------------------------------------
Write-Header 'DEMO 4c  -  Validate it with Test-PlasterManifest'

$manifest = Test-PlasterManifest -Path (Join-Path $scratch 'plasterManifest.json') 3>$null
if ($manifest) {
    Write-Host "`n   Valid. name='$($manifest.plasterManifest.metadata.name)' type='$($manifest.plasterManifest.templateType)'" -ForegroundColor Green
}

# ----------------------------------------------------------------------------
Write-Header 'DEMO 4d  -  Use the template we just authored'

# Two quick edits to make the round-trip meaningful:
#  1. Add a 'Thing' parameter so there is a $PLASTER_PARAM_Thing to substitute.
#  2. New-PlasterManifest -AddContent emits 'file' actions (verbatim copy). Switch
#     them to 'templateFile' so the <%= ... %> placeholders actually expand.
$json = Get-Content (Join-Path $scratch 'plasterManifest.json') -Raw | ConvertFrom-Json
$json.parameters = @(
    [pscustomobject]@{ name = 'Thing'; type = 'text'; prompt = 'Name the thing'; default = 'Sproket' }
)
foreach ($action in $json.content) { $action.type = 'templateFile' }
$json | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $scratch 'plasterManifest.json')

$dst = Join-Path $outputDir '04-authored-output'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Invoke-Plaster -TemplatePath $scratch -DestinationPath $dst -NoLogo -Thing 'Sproket'

Write-Host "`n   --- thing.ps1 (generated from our authored template) ---" -ForegroundColor DarkGray
Get-Content (Join-Path $dst 'thing.ps1') | ForEach-Object { "   $_" }

Write-Host "`nDemo 4 complete.`n" -ForegroundColor Cyan
