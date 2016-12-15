
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

Microsoft.PowerShell.Utility\Import-LocalizedData LocalizedData -FileName Plaster.Resources.psd1 -ErrorAction SilentlyContinue

# Module variables
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$LatestSupportedSchemaVersion = [System.Version]'0.5'
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$TargetNamespace = "http://www.microsoft.com/schemas/PowerShell/Plaster/v1"
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
$DefaultEncoding = 'Default'

if (($PSVersionTable.PSVersion.Major -le 5) -or ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows) {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ParameterDefaultValueStoreRootPath = "$env:LOCALAPPDATA\Plaster"
}
elseif ($IsLinux) {
    # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ParameterDefaultValueStoreRootPath = if ($XDG_DATA_HOME) { "$XDG_DATA_HOME/plaster"  } else { "$Home/.local/share/plaster" }
}
else {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ParameterDefaultValueStoreRootPath = "$Home/.plaster"
}

# Dot source the individual module command scripts.
. $PSScriptRoot\NewPlasterManifest.ps1
. $PSScriptRoot\TestPlasterManifest.ps1
. $PSScriptRoot\InvokePlaster.ps1

Export-ModuleMember -Function *-*
