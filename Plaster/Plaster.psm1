# spell-checker:ignore Multichoice Assigments
# Import localized data with improved error handling
try {
    $importLocalizedDataSplat = @{
        BindingVariable = 'LocalizedData'
        FileName = 'Plaster.Resources.psd1'
        ErrorAction = 'SilentlyContinue'
    }
    Microsoft.PowerShell.Utility\Import-LocalizedData @importLocalizedDataSplat
} catch {
    Write-Warning "Failed to import localized data: $_"
}

# Module variables with proper scoping and type safety
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$PlasterVersion = (Test-ModuleManifest -Path (Join-Path $PSScriptRoot 'Plaster.psd1')).Version

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$JsonSchemaPath = Join-Path $PSScriptRoot "Schema\plaster-manifest-v2.json"

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LatestSupportedSchemaVersion = [System.Version]'1.2'

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TargetNamespace = "http://www.microsoft.com/schemas/PowerShell/Plaster/v1"

[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$DefaultEncoding = 'UTF8-NoBOM'

# Cross-platform parameter store path configuration
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$ParameterDefaultValueStoreRootPath = switch ($true) {
    # Windows (both Desktop and Core)
    (($PSVersionTable.PSVersion.Major -le 5) -or ($PSVersionTable.PSEdition -eq 'Desktop') -or ($IsWindows -eq $true)) {
        if ($env:LOCALAPPDATA) {
            "$env:LOCALAPPDATA\Plaster"
        } else {
            "$env:USERPROFILE\AppData\Local\Plaster"
        }
    }
    # Linux - Follow XDG Base Directory Specification
    ($IsLinux -eq $true) {
        if ($env:XDG_DATA_HOME) {
            "$env:XDG_DATA_HOME/plaster"
        } else {
            "$Home/.local/share/plaster"
        }
    }
    # macOS and other Unix-like systems
    default {
        "$Home/.plaster"
    }
}

# Enhanced platform detection with fallback
if (-not (Get-Variable -Name 'IsWindows' -ErrorAction SilentlyContinue)) {
    $script:IsWindows = $PSVersionTable.PSVersion.Major -le 5 -or $PSVersionTable.PSEdition -eq 'Desktop'
}

if (-not (Get-Variable -Name 'IsLinux' -ErrorAction SilentlyContinue)) {
    $script:IsLinux = $false
}

if (-not (Get-Variable -Name 'IsMacOS' -ErrorAction SilentlyContinue)) {
    $script:IsMacOS = $false
}

# .NET Core compatibility check for XML Schema validation
$script:XmlSchemaValidationSupported = $null -ne ('System.Xml.Schema.XmlSchemaSet' -as [type])

if (-not $script:XmlSchemaValidationSupported) {
    Write-Verbose "XML Schema validation is not supported on this platform. Limited validation will be performed."
}

# Module logging configuration
$script:LogLevel = if ($env:PLASTER_LOG_LEVEL) { $env:PLASTER_LOG_LEVEL } else { 'Information' }

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

# Module cleanup on removal
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-PlasterLog -Level Information -Message "Plaster module is being removed"

    # Clean up any module-scoped variables or resources
    Remove-Variable -Name 'PlasterVersion' -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name 'LatestSupportedSchemaVersion' -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name 'TargetNamespace' -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name 'DefaultEncoding' -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name 'ParameterDefaultValueStoreRootPath' -Scope Script -ErrorAction SilentlyContinue
}

# Module initialization complete
Write-PlasterLog -Level Information -Message "Plaster v$PlasterVersion module loaded successfully (PowerShell $($PSVersionTable.PSVersion))"
