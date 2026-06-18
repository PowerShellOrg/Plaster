#requires -Modules Pester
# Minimal build script for <%= $PLASTER_PARAM_ModuleName %>
[CmdletBinding()]
param([string]$Task = 'Test')

Write-Host "Running '$Task' for <%= $PLASTER_PARAM_ModuleName %>..." -ForegroundColor Cyan
Invoke-Pester -Path "$PSScriptRoot/tests"
