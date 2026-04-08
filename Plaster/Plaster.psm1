# spell-checker:ignore Multichoice Assigments
# Import localized data
data LocalizedData {
    # culture="en-US"
    ConvertFrom-StringData @'
    DestPath_F1=Destination path: {0}
    ErrorFailedToLoadStoreFile_F1=Failed to load the default value store file: '{0}'.
    ErrorProcessingDynamicParams_F1=Failed to create dynamic parameters from the template's manifest file.  Template-based dynamic parameters will not be available until the error is corrected.  The error was: {0}
    ErrorTemplatePathIsInvalid_F1=The TemplatePath parameter value must refer to an existing directory. The specified path '{0}' does not.
    ErrorUnencryptingSecureString_F1=Failed to unencrypt value for parameter '{0}'.
    ErrorPathDoesNotExist_F1=Cannot find path '{0}' because it does not exist.
    ErrorPathMustBeRelativePath_F2=The path '{0}' specified in the {1} directive in the template manifest cannot be an absolute path.  Change the path to a relative path.
    ErrorPathMustBeUnderDestPath_F2=The path '{0}' must be under the specified DestinationPath '{1}'.
    ExpressionInvalid_F2=The expression '{0}' is invalid or threw an exception. Error: {1}
    ExpressionNonTermErrors_F2=The expression '{0}' generated error output - {1}
    ExpressionExecError_F2=PowerShell expression failed execution. Location: {0}. Error: {1}
    ExpressionErrorLocationFile_F2=<{0}> attribute '{1}'
    ExpressionErrorLocationModify_F1=<modify> attribute '{0}'
    ExpressionErrorLocationNewModManifest_F1=<newModuleManifest> attribute '{0}'
    ExpressionErrorLocationParameter_F2=<parameter> name='{0}', attribute '{1}'
    ExpressionErrorLocationRequireModule_F2=<requireModule> name='{0}', attribute '{1}'
    ExpressionInvalidCondition_F3=The Plaster manifest condition '{0}' failed. Location: {1}. Error: {2}
    InterpolationError_F3=The Plaster manifest attribute value '{0}' failed string interpolation. Location: {1}. Error: {2}
    FileConflict=Plaster file conflict
    ManifestFileMissing_F1=The Plaster manifest file '{0}' was not found.
    ManifestMissingDocElement_F2=The Plaster manifest file '{0}' is missing the document element. It should be specified as <plasterManifest xmlns="{1}"></plasterManifest>.
    ManifestMissingDocTargetNamespace_F2=The Plaster manifest file '{0}' is missing or has an invalid target namespace on the document element. It should be specified as <plasterManifest xmlns="{1}"></plasterManifest>.
    ManifestPlasterVersionNotSupported_F2=The template file '{0}' specifies a plasterVersion of {1} which is greater than the installed version of Plaster. Update the Plaster module and try again.
    ManifestSchemaInvalidAttrValue_F5=Invalid '{0}' attribute value '{1}' on '{2}' element in file '{3}'. Error: {4}
    ManifestSchemaInvalidCondition_F3=Invalid condition '{0}' in file '{1}'. Error: {2}
    ManifestSchemaInvalidChoiceDefault_F3=Invalid default attribute value '{0}' for parameter '{1}' in file '{2}'. The default value must specify a zero-based integer index that corresponds to the default choice.
    ManifestSchemaInvalidMultichoiceDefault_F3=Invalid default attribute value '{0}' for parameter '{1}' in file '{2}'. The default value must specify one or more zero-based integer indexes in a comma separated list that correspond to the default choices.
    ManifestSchemaInvalidRequireModuleAttrs_F2=The requireModule attribute 'requiredVersion' for module '{0}' in file '{1}' cannot be used together with either the 'minimumVersion' or 'maximumVersion' attribute.
    ManifestSchemaValidationError_F2=Plaster manifest schema error in file '{0}'. Error: {1}
    ManifestSchemaVersionNotSupported_F2=The template's manifest schema version ({0}) in file '{1}' requires a newer version of Plaster. Update the Plaster module and try again.
    ManifestErrorReading_F1=Error reading Plaster manifest: {0}
    ManifestNotValid_F1=The Plaster manifest '{0}' is not valid.
    ManifestNotValidVerbose_F1=The Plaster manifest '{0}' is not valid. Specify -Verbose to see the specific schema errors.
    ManifestNotWellFormedXml_F2=The Plaster manifest '{0}' is not a well-formed XML file. {1}
    ManifestWrongFilename_F1=The Plaster manifest filename '{0}' is not valid. The value of the Path argument must refer to a file named 'plasterManifest.xml' or 'plasterManifest_<culture>.xml'. Change the Plaster manifest filename and then try again.
    MissingParameterPrompt_F1=<Missing prompt value for parameter '{0}'>
    NewModManifest_CreatingDir_F1=Creating destination directory for module manifest: {0}
    OpConflict=Conflict
    OpCreate=Create
    OpForce=Force
    OpIdentical=Identical
    OpMissing=Missing
    OpModify=Modify
    OpUpdate=Update
    OpVerify=Verify
    OverwriteFile_F1=Overwrite {0}
    ParameterTypeChoiceMultipleDefault_F1=Parameter name {0} is of type='choice' and can only have one default value.
    RequireModuleVerified_F2=The required module {0}{1} is already installed.
    RequireModuleMissing_F2=The required module {0}{1} was not found.
    RequireModuleMinVersion_F1=minimum version: {0}
    RequireModuleMaxVersion_F1=maximum version: {0}
    RequireModuleRequiredVersion_F1=required version: {0}
    ShouldCreateNewPlasterManifest=Create Plaster manifest
    ShouldProcessCreateDir=Create directory
    ShouldProcessExpandTemplate=Expand template file
    ShouldProcessNewModuleManifest=Create new module manifest
    TempFileOperation_F1={0} into temp file before copying to destination
    TempFileTarget_F1=temp file for '{0}'
    TestPlasterNoXmlSchemaValidationWarning=The version of .NET Core that PowerShell is running on does not support XML schema-based validation. Test-PlasterManifest will operate in "limited validation" mode primarily verifying the specified manifest file is well-formed XML. For full, XML schema-based validation, run this command on Windows PowerShell.
    UnrecognizedParametersElement_F1=Unrecognized manifest parameters child element: {0}.
    UnrecognizedParameterType_F2=Unrecognized parameter type '{0}' on parameter name '{1}'.
    UnrecognizedContentElement_F1=Unrecognized manifest content child element: {0}.
'@
}

# Import localized data with improved error handling
try {
    Microsoft.PowerShell.Utility\Import-LocalizedData LocalizedData -FileName 'Plaster.Resources.psd1' -ErrorAction SilentlyContinue
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

# Register argument completers
Register-ArgumentCompleter -CommandName Invoke-Plaster -ParameterName TemplateName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Trim single, or double quotes from the start/end of the word to complete.
    if ($wordToComplete -match '^[''"]') {
        $wordToComplete = $wordToComplete.Trim($Matches.Values[0])
    }

    # Get all unique names starting with the characters provided, if any.
    Get-PlasterTemplate -Name "$wordToComplete*" | Select-Object Name -Unique | ForEach-Object {
        # Wrap the completion in single quotes if it contains any whitespace.
        if ($_.Name -match '\s') {
            "'{0}'" -f $_.Name
        } else {
            $_.Name
        }
    }
}

# Module initialization complete
Write-PlasterLog -Level Information -Message "Plaster v$PlasterVersion module loaded successfully (PowerShell $($PSVersionTable.PSVersion))"
