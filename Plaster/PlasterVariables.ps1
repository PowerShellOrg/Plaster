# Requires -Version 5.1

# Global variables and constants for Plaster 2.0

# Enhanced $TargetNamespace definition with proper scoping
if (-not (Get-Variable -Name 'TargetNamespace' -Scope Script -ErrorAction SilentlyContinue)) {
    Set-Variable -Name 'TargetNamespace' -Value 'http://www.microsoft.com/schemas/PowerShell/Plaster/v1' -Scope Script -Option ReadOnly
}

# Enhanced $DefaultEncoding definition
if (-not (Get-Variable -Name 'DefaultEncoding' -Scope Script -ErrorAction SilentlyContinue)) {
    Set-Variable -Name 'DefaultEncoding' -Value 'UTF8-NoBOM' -Scope Script -Option ReadOnly
}

# JSON Schema version for new manifests
if (-not (Get-Variable -Name 'JsonSchemaVersion' -Scope Script -ErrorAction SilentlyContinue)) {
    Set-Variable -Name 'JsonSchemaVersion' -Value '2.0' -Scope Script -Option ReadOnly
}

# Export the variables that need to be available globally
Export-ModuleMember -Variable @('TargetNamespace', 'DefaultEncoding', 'JsonSchemaVersion')