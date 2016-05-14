data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
    OpCreate=Create
    OpIdentical=Identical
    OpConflict=Conflict
    OpModify=Modify
    OpExpand=Expand
    ErrorProcessingDynamicParams_F1=Error processing dynamic parameters: {0}
    ManifestWrongFilename_F1=The manifest filename must be plasterManifest.xml not '{0}'.
    ManifestNotValidXml_F1=The manifest is not a valid XML file: {0}
    ManifestMissingElement_F1=The Plaster manifest is missing the {0} element.
    ManifestMissingAttribute_F2=The Plaster manifest element {0} is missing the required attribute {1}.
    UnrecognizedParametersElement_F1=Unrecognized manifest parameters child element: {0}.
    UnrecognizedParameterType_F2=Unrecognized parameter type '{0}' on parameter name '{1}'.
    UnrecognizedContentElement_F1=Unrecognized manifest content child element: {0}.
    UnrecognizedAttribute_F2=Unrecognized manifest attribute {0} on element {1}.
    ParameterTypeChoiceMultipleDefault_F1=Parameter name {0} is of type='choice' and can only have one default value.
    ShouldProcessCreateDir=Create directory
    ShouldProcessGenerateModuleManifest=Generating a new module manifest
    ShouldProcessReplaceContent_F2=Replace '{0}' with '{1}'
    ShouldProcessTemplateFile=Processing template file
'@
}

Import-LocalizedData LocalizedData -FileName PlasterResources

. $PSScriptRoot\TestPlasterManifest.ps1
. $PSScriptRoot\InvokePlaster.ps1

Export-ModuleMember -Function *-*
