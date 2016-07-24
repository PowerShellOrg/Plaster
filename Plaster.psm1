#Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

$LocalizedData = data {
    # culture="en-US"
    ConvertFrom-StringData @'
    ErrorFailedToLoadStoreFile_F1=Failed to load the default value store file: '{0}'.
    ErrorProcessingDynamicParams_F1=Error processing dynamic parameters: {0}
    ErrorUnencryptingSecureString_F1=Failed to unencrypt value for parameter '{0}'.
    ErrorPathDoesNotExist_F1=Cannot find path '{0}' because it does not exist.
    FileConflict=Plaster file conflict
    ManifestFileMissing_F1=The Plaster manifest file '{0}' was not found.
    ManifestMissingDocElement_F2=The Plaster manifest file '{0}' is missing the document element <plasterManifest xmlns="{1}"></plasterManifest>.
    ManifestMissingDocTargetNamespace_F2=The Plaster manifest file '{0}' is missing or has an invalid target namespace on the document element. It should be specified as <plasterManifest xmlns="{1}"></plasterManifest>.
    ManifestSchemaValidationError_F1=Plaster manifest schema error: {0}
    ManifestErrorReading_F1=Plaster manifest error: {0}
    ManifestNotValid_F1=The Plaster manifest '{0}' is not valid. Specify -Verbose to see the specific schema errors.
    ManifestNotWellFormedXml_F2=The Plaster manifest '{0}' is not a well-formed XML file. {1}
    ManifestWrongFilename_F1=The Plaster manifest filename '{0}' is not valid. The value of the Path argument must refer to a file named 'plasterManifest.xml'. Change the plaster manifest filename to 'plasterManifest.xml', and then try again.
    OpCreate=Create
    OpConflict=Conflict
    OpExpand=Expand
    OpIdentical=Identical
    OpModify=Modify
    OverwriteFile_F1=Overwrite {0}
    ParameterTypeChoiceMultipleDefault_F1=Parameter name {0} is of type='choice' and can only have one default value.
    ShouldProcessCreateDir=Create directory
    ShouldProcessGenerateModuleManifest=Generating a new module manifest
    ShouldProcessModifyContent=Modifying file
    ShouldProcessTemplateFile=Processing template file
    SubsitutionExpressionInvalid_F1=The substitution expression '{0}' is not supported.  Only string constants and string constants with variable expressions are supported.
    UnrecognizedParametersElement_F1=Unrecognized manifest parameters child element: {0}.
    UnrecognizedParameterType_F2=Unrecognized parameter type '{0}' on parameter name '{1}'.
    UnrecognizedContentElement_F1=Unrecognized manifest content child element: {0}.
'@
}

Microsoft.PowerShell.Utility\Import-LocalizedData LocalizedData -FileName Plaster.Resources.psd1 -ErrorAction SilentlyContinue

# Module variables
$ParameterDefaultValueStoreRootPath = "$env:LOCALAPPDATA\Plaster"
$DefaultEncoding = 'Default'

# Shared, private helper functions
function ExtractTemplateAndReturnPath([string]$TemplatePath) {
    $item = Get-Item -LiteralPath $TemplatePath

    if ($item.Attributes -band [System.IO.FileAttributes]::Directory) {
        $item.FullName
    }
    else {
        do {
            $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
        } while (Test-Path -LiteralPath $tempPath)

        [void](New-Item $tempPath -ItemType Directory)
        [void](Microsoft.PowerShell.Archive\Expand-Archive -LiteralPath $TemplatePath -DestinationPath $tempPath)
        $tempPath
    }
}

# Dot source the module command scripts
. $PSScriptRoot\TestPlasterManifest.ps1
. $PSScriptRoot\InvokePlaster.ps1

Export-ModuleMember -Function *-*
