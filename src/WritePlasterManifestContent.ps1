<#
.SYNOPSIS
A simple helper function to create a plaster message xml block
.DESCRIPTION
A simple helper function to create a plaster message xml block
.PARAMETER Message
The message to display
.PARAMETER Condition
The condition to match to display the message
.PARAMETER NoNewLine
The message will not include a newline at the end
.EXAMPLE
Write-PlasterManifestContentMessage -Message 'Building out your module and preparing the environment...' -NoNewLine
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
#>
function Write-PlasterManifestContentMessage {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Position = 1)]
        [string]$Condition,
        [Parameter(Position = 2)]
        [bool]$NoNewLine
    )

    process {
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('message')

        # Set the message
        $oXMLContent.InnerText = $Message

        if (-not [string]::IsNullOrEmpty($Condition)) {
            $oXMLContent.SetAttribute("condition", $Condition)
        }
        if ($NoNewLine) {
            $oXMLContent.SetAttribute("noNewLine", 'true')
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A simple helper function to create a plaster file xml block
.DESCRIPTION
A simple helper function to create a plaster file xml block.
.PARAMETER Source
Source file
.PARAMETER Destination
Destination file
.PARAMETER Condition
Used to determine whether this directive is executed
.PARAMETER OpenInEditor
Specifies whether the file should be opened in the editor (true) after scaffolding or not (false)
.EXAMPLE
TBD
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
#>
function Write-PlasterManifestContentFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Destination,
        [Parameter(Position = 2)]
        [string]$Condition,
        [Parameter(Position = 3)]
        [bool]$openInEditor
    )

    process {
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('file')

        # Uses: source, destination, condition, openInEditor
        $oXMLContent.SetAttribute("source", $Source)
        $oXMLContent.SetAttribute("destination", $Destination)
        if (-not [string]::IsNullOrEmpty($Condition)) {
            $oXMLContent.SetAttribute("condition", $Condition)
        }
        if ($openInEditor) {
            $oXMLContent.SetAttribute("openInEditor", 'true')
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A simple helper function to create a plaster templatefile xml block
.DESCRIPTION
A simple helper function to create a plaster templatefile xml block.
.PARAMETER Source
Source file
.PARAMETER Destination
Destination file
.PARAMETER Condition
Used to determine whether this directive is executed
.PARAMETER OpenInEditor
Specifies whether the file should be opened in the editor (true) after scaffolding or not (false)
.PARAMETER Encoding
Encoding for created file
.EXAMPLE
TBD
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
#>
function Write-PlasterManifestContentTemplateFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Destination,
        [Parameter(Position = 2)]
        [string]$Condition,
        [Parameter(Position = 3)]
        [bool]$openInEditor,
        [Parameter(Position = 4)]
        [string]$Encoding
    )

    process {
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('templateFile')
        $oXMLContent.SetAttribute("source", $Source)
        $oXMLContent.SetAttribute("destination", $Destination)
        if (-not [string]::IsNullOrEmpty($Condition)) {
            $oXMLContent.SetAttribute("condition", $Condition)
        }
        if (-not [string]::IsNullOrEmpty($Encoding)) {
            $oXMLContent.SetAttribute("encoding", $Encoding)
        }
        if ($openInEditor) {
            $oXMLContent.SetAttribute("openInEditor", 'true')
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A simple helper function to create a plaster newModuleManifest xml block
.DESCRIPTION
A simple helper function to create a plaster newModuleManifest xml block.
.PARAMETER Destination
Where the module manifest will be created. If it already exists then existing values will be resused if they are not defined in this content block
.PARAMETER Condition
Used to determine whether this directive is executed
.PARAMETER OpenInEditor
Specifies whether the file should be opened in the editor (true) after scaffolding or not (false)
.PARAMETER Encoding
Encoding for created file
.PARAMETER author
Module manifest author
.PARAMETER companyName
Module manifest company
.PARAMETER description
Module description
.PARAMETER moduleVersion
Module version
.PARAMETER rootModule
Root module for th emanifest
.PARAMETER copyright
Module manifest copyright
.PARAMETER tags
Module tags
.PARAMETER projectUri
Module project website
.PARAMETER licenseUri
Module license website
.PARAMETER iconUri
Module icon link
.PARAMETER helpInfoUri
Module help website
.PARAMETER nestedModules
Nested modules
.PARAMETER requiredModules
Required modules for the module manifest
.PARAMETER typesToProcess
Types to process for this module
.PARAMETER formatsToProcess
Formats to process for this module
.PARAMETER scriptsToProcess
Scripts to process for this module
.PARAMETER requiredAssemblies
Required assemblies for this module
.PARAMETER fileList
List of files for this module
.PARAMETER moduleList
List of modules for thid module
.PARAMETER functionsToExport
Functions to export for this module
.PARAMETER aliasesToExport
Aliases to export for th is module
.PARAMETER variablesToExport
Variables to export for this module
.PARAMETER cmdletsToExport
Cmdlets to export for this module
.PARAMETER dscResourcesToExport
DSC resources to export for this module
.PARAMETER compatiblePSEditions
Compatible versions of PowerShell for this module
.PARAMETER defaultCommandPrefix
Default prefix for commands exported from this module
.EXAMPLE
TBD
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
.LINK
https://github.com/PowerShell/Plaster/blob/master/docs/en-US/about_Plaster_CreatingAManifest.help.md
#>
function Write-PlasterManifestContentNewModuleManifest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$destination,
        [string]$condition,
        [bool]$openInEditor,
        [string]$encoding,
        [string]$author,
        [string]$companyName,
        [string]$description,
        [string]$moduleVersion,
        [string]$rootModule,
        [string]$copyright,
        [string]$tags,
        [string]$projectUri,
        [string]$licenseUri,
        [string]$iconUri,
        [string]$helpInfoUri,
        [string]$nestedModules,
        [string]$requiredModules,
        [string]$typesToProcess,
        [string]$formatsToProcess,
        [string]$scriptsToProcess,
        [string]$requiredAssemblies,
        [string]$fileList,
        [string]$moduleList,
        [string]$functionsToExport,
        [string]$aliasesToExport,
        [string]$variablesToExport,
        [string]$cmdletsToExport,
        [string]$dscResourcesToExport,
        [string]$compatiblePSEditions,
        [string]$defaultCommandPrefix
    )

    process {
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('newModuleManifest')

        $MyParams = $PSCmdlet.MyInvocation.BoundParameters
        $MyParams.Keys | ForEach-Object {
            Write-Verbose "..Adding parameter $($_)"
            $ParamName = $_
            $ParamType = $MyParams[$_].GetType().Name
            $ParamValue = $MyParams[$_]
            switch ($ParamType) {
                'SwitchParameter' {
                    $oXMLContent.SetAttribute($ParamName, 'true')
                }
                default {
                    $oXMLContent.SetAttribute($ParamName, $ParamValue)
                }
            }
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A simple helper function to create a plaster modify xml block
.DESCRIPTION
A simple helper function to create a plaster modify xml block.
.PARAMETER Path
Specifies the relative path, under the destination folder, of the file to be modified
.PARAMETER Encoding
File encoding for the output
.PARAMETER Original
The original text, or regular expression match to replace
.PARAMETER OriginalExpand
Whether to expand variables within the original for match.
.PARAMETER Substitute
The replacement text to substitute in place of the original text
.PARAMETER SubstituteExpand
Whether to expand variables within the substitute text
.PARAMETER Condition
Used to determine whether this directive is executed
.PARAMETER OpenInEditor
Specifies whether the file should be opened in the editor (true) after scaffolding or not (false)
.EXAMPLE
Write-PlasterManifestContentModify -Path '.vscode\tasks.json' -Encoding 'UTF8' -Condition '$PLASTER_PARAM_Editor -eq "VSCode"' -ReplaceCondition "`$PLASTER_FileContent -notmatch '// Author:'" -Original '(?s)^(.*)' -Substitute '// Author: $PLASTER_PARAM_FullName`r`n`$1' -SubstituteExpand $true
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
.LINK
https://github.com/PowerShell/Plaster/blob/master/docs/en-US/about_Plaster_CreatingAManifest.help.md
#>
function Write-PlasterManifestContentModify {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Original,
        [bool]$OriginalExpand,
        [string]$Substitute,
        [bool]$SubstituteExpand,
        [string]$Condition,
        [string]$ReplaceCondition,
        [bool]$openInEditor,
        [string]$Encoding
    )

    process {
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('Modify')

        $oXMLContent.SetAttribute("path", $Path)
        if (-not [string]::IsNullOrEmpty($Condition)) {
            $oXMLContent.SetAttribute("condition", $Condition)
        }
        if (-not [string]::IsNullOrEmpty($Encoding)) {
            $oXMLContent.SetAttribute("encoding", $Encoding)
        }
        if ($openInEditor) {
            $oXMLContent.SetAttribute("openInEditor", 'true')
        }

        $null = $oXMLRoot.appendChild($oXMLContent)

        $oXMLReplace = $oXMLRoot.CreateElement("replace")
        if (-not [string]::IsNullOrEmpty($ReplaceCondition)) {
            $oXMLReplace.SetAttribute("condition", $ReplaceCondition)
        }
        $null = $oXMLRoot.Modify.appendChild($oXMLReplace)

        if (-not [string]::IsNullOrEmpty($Original)) {
            $oXMLReplaceOriginal = $oXMLRoot.CreateElement("original")
            $oXMLReplaceOriginal.InnerText = $Original
            if ($OriginalExpand) {
                $oXMLReplaceOriginal.SetAttribute("expand", 'true')
            }
            $null = $oXMLRoot.modify['replace'].appendChild($oXMLReplaceOriginal)
        }
        if (-not [string]::IsNullOrEmpty($Substitute)) {
            $oXMLReplaceSub = $oXMLRoot.CreateElement("substitute")
            $oXMLReplaceSub.InnerText = $Substitute
            if ($SubstituteExpand) {
                $oXMLReplaceSub.SetAttribute("expand", 'true')
            }
            $null = $oXMLRoot.modify['replace'].appendChild($oXMLReplaceSub)
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A simple helper function to create a plaster requireModule xml block
.DESCRIPTION
A simple helper function to create a plaster requireModule xml block.
.PARAMETER Name
Name of required module
.PARAMETER Condition
Condition to be met to process this content block
.PARAMETER MinimumVersion
Minimum version for module requirement
.PARAMETER MaximumVersion
Maximum version for module requirement
.PARAMETER RequiredVersion
Required module version.
.PARAMETER Message
Message to display if the module requirements are not met for requireModule. For message this is just the message to display.
.EXAMPLE
Write-PlasterManifestContentRequireModule -Name 'Pester' -MinimumVersion '4.0.2' -Message 'Pester 4.0.2 is required for this plaster scaffold.'
.NOTES
This only outputs a an xml string that needs to be combined as part of a larger content block to create your manifest file.
.LINK
https://github.com/PowerShell/Plaster/blob/master/docs/en-US/about_Plaster_CreatingAManifest.help.md
#>
function Write-PlasterManifestContentRequireModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 1)]
        [string]$Condition,
        [Parameter(Position = 2)]
        [string]$MinimumVersion,
        [Parameter(Position = 3)]
        [string]$MaximumVersion,
        [Parameter(Position = 4)]
        [string]$RequiredVersion,
        [Parameter(Position = 5)]
        [string]$Message
    )

    process {
        if ($RequiredVersion -and ($MinimumVersion -or $MaximumVersion)) {
            throw 'Unable to use either MinimumVersion or MaximumVersion when defining RequiredVersion.'
        }
        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        # New Node
        $oXMLContent = $oXMLRoot.CreateElement('requireModule')
        if (-not [string]::IsNullOrEmpty($Condition)) {
            $oXMLContent.SetAttribute("condition", $Condition)
        }
        if (-not [string]::IsNullOrEmpty($Name)) {
            $oXMLContent.SetAttribute("name", $Name)
        }
        if (-not [string]::IsNullOrEmpty($MinimumVersion)) {
            $oXMLContent.SetAttribute("minimumVersion", $MinimumVersion)
        }
        if (-not [string]::IsNullOrEmpty($MaximumVersion)) {
            $oXMLContent.SetAttribute("maximumVersion", $MaximumVersion)
        }
        if (-not [string]::IsNullOrEmpty($RequiredVersion)) {
            $oXMLContent.SetAttribute("requiredVersion", $RequiredVersion)
        }
        if (-not [string]::IsNullOrEmpty($Message)) {
            $oXMLContent.SetAttribute("message", $Message)
        }

        # Append as child to an existing node
        $null = $oXMLRoot.appendChild($oXMLContent)

        # Return the result
        $oXMLRoot.InnerXML
    }
}

<#
.SYNOPSIS
A wraper function to create a plaster content xml block.

.DESCRIPTION
A simple helper function to create a plaster content xml block. This function
is best used with an array of hashtables for rapid creation of a Plaster content
block.
.PARAMETER ContentType
Type of content block to create
.PARAMETER Path
Specifies the relative path, under the destination folder, of the file to be modified
.PARAMETER Source
Source file
.PARAMETER Destination
Where the module manifest, templatefile, or template will be created
.PARAMETER Condition
Used to determine whether this directive is executed
.PARAMETER OpenInEditor
Specifies whether the file should be opened in the editor (true) after scaffolding or not (false)
.PARAMETER Encoding
Encoding for created file
.PARAMETER author
Module manifest author
.PARAMETER companyName
Module manifest company
.PARAMETER description
Module description
.PARAMETER moduleVersion
Module version
.PARAMETER rootModule
Root module for th emanifest
.PARAMETER copyright
Module manifest copyright
.PARAMETER tags
Module tags
.PARAMETER projectUri
Module project website
.PARAMETER licenseUri
Module license website
.PARAMETER iconUri
Module icon link
.PARAMETER helpInfoUri
Module help website
.PARAMETER nestedModules
Nested modules
.PARAMETER requiredModules
Required modules for the module manifest
.PARAMETER typesToProcess
Types to process for this module
.PARAMETER formatsToProcess
Formats to process for this module
.PARAMETER scriptsToProcess
Scripts to process for this module
.PARAMETER requiredAssemblies
Required assemblies for this module
.PARAMETER fileList
List of files for this module
.PARAMETER moduleList
List of modules for thid module
.PARAMETER functionsToExport
Functions to export for this module
.PARAMETER aliasesToExport
Aliases to export for th is module
.PARAMETER variablesToExport
Variables to export for this module
.PARAMETER cmdletsToExport
Cmdlets to export for this module
.PARAMETER dscResourcesToExport
DSC resources to export for this module
.PARAMETER compatiblePSEditions
Compatible versions of PowerShell for this module
.PARAMETER defaultCommandPrefix
Default prefix for commands exported from this module
.PARAMETER MinimumVersion
Minimum version for module requirement
.PARAMETER MaximumVersion
Maximum version for module requirement
.PARAMETER RequiredVersion
Required module version.
.PARAMETER Message
Message to display if the module requirements are not met for requireModule. For message this is just the message to display.
.PARAMETER NoNewLine
The message will not include a newline at the end
.PARAMETER Original
The original text, or regular expression match to replace
.PARAMETER OriginalExpand
Whether to expand variables within the original for match.
.PARAMETER Substitute
The replacement text to substitute in place of the original text
.PARAMETER SubstituteExpand
Whether to expand variables within the substitute text
.EXAMPLE
$MyPlasterContent = @(
    @{
        'ContentType' = 'Message'
        'Message' = 'Building out your module and preparing the environment...'
        'NoNewLine' = $true
    },
    @{
        'ContentType' = 'newModuleManifest'
        'Destination' = '${PLASTER_PARAM_ModuleName}.psd1'
        'moduleVersion' = '${PLASTER_PARAM_ModuleVersion}'
        'rootModule' = '${PLASTER_PARAM_ModuleName}.psm1'
        'copyright' = '(c) 2017 ${PLASTER_PARAM_ModuleAuthor}. All rights reserved.'
        'projectURI' = '${PLASTER_PARAM_ModuleWebsite}'
        'licenseURI' = '${PLASTER_PARAM_ModuleWebsite}/raw/master/license.md'
        'iconURI' = '${PLASTER_PARAM_ModuleWebsite}/raw/master/src/other/powershell-project.png'
        'author' = '${PLASTER_PARAM_ModuleAuthor}'
        'companyname' = '${PLASTER_PARAM_ModuleAuthor}'
        'description' = '${PLASTER_PARAM_ModuleDescription}'
        'tags' = '${PLASTER_PARAM_tags}'
        'encoding' = 'UTF8-NoBOM'
    },
    @{
        'ContentType' = 'file'
        'Source' = 'scaffold\src\other\*'
        'Destination' = 'src\${PLASTER_PARAM_OtherModuleSource}'
    },
    @{
        'ContentType' = 'file'
        'Source' = 'scaffold\src\private\*'
        'Destination' = 'src\${PLASTER_PARAM_PrivateFunctionSource}'
    },
    @{
        'ContentType' = 'file'
        'Source' = 'scaffold\src\public\*'
        'Destination' = 'src\${PLASTER_PARAM_PublicFunctionSource}'
    },
    @{
        'ContentType' = 'templateFile'
        'Source' = 'scaffold\ModuleName.psm1'
        'Destination' = '${PLASTER_PARAM_ModuleName}.psm1'
    },
    @{
        'ContentType' = 'Modify'
        'Path' = '.vscode\tasks.json'
        'Encoding' = 'UTF8'
        'Condition' = '$PLASTER_PARAM_Editor -eq "VSCode"'
        'ReplaceCondition' = "`$PLASTER_FileContent -notmatch '// Author:'"
        'Original' = '(?s)^(.*)'
        'Substitute' = '// Author: $PLASTER_PARAM_FullName`r`n`$1'
        'SubstituteExpand' = $true
    },
    @{
        'ContentType' = 'Message'
        'Message' = '-= COMPLETE! =-'
    }
) | Write-PlasterManifestContent
.NOTES
Not all content types are sanitized for valid output yet so it is vital to test your resulting
Plaster manifest file with Test-PlasterManifest -Verbose.
.LINK
https://github.com/PowerShell/Plaster/blob/master/docs/en-US/about_Plaster_CreatingAManifest.help.md
#>
function Write-PlasterManifestContent {
[CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('File', 'TemplateFile', 'Message', 'Modify', 'newModuleManifest', 'requireModule')]
        [Alias('Type')]
        [string]$ContentType = 'Message',
        [string]$Condition,
        [string]$Source,
        [string]$Destination,
        [bool]$OpenInEditor,
        [string]$Encoding,
        [bool]$NoNewLine,
        [string]$ReplaceCondition,
        [string]$Original,
        [bool]$OriginalExpand,
        [string]$Substitute,
        [bool]$SubstituteExpand,
        [string]$Path,
        [string]$author,
        [string]$companyName,
        [string]$description,
        [string]$moduleVersion,
        [string]$rootModule,
        [string]$copyright,
        [string]$tags,
        [string]$projectUri,
        [string]$licenseUri,
        [string]$iconUri,
        [string]$helpInfoUri,
        [string]$nestedModules,
        [string]$requiredModules,
        [string]$typesToProcess,
        [string]$formatsToProcess,
        [string]$scriptsToProcess,
        [string]$requiredAssemblies,
        [string]$fileList,
        [string]$moduleList,
        [string]$functionsToExport,
        [string]$aliasesToExport,
        [string]$variablesToExport,
        [string]$cmdletsToExport,
        [string]$dscResourcesToExport,
        [string]$compatiblePSEditions,
        [string]$defaultCommandPrefix,
        [string]$Name,
        [string]$MinimumVersion,
        [string]$MaximumVersion,
        [string]$RequiredVersion,
        [string]$Message,
        [Parameter(ParameterSetName = "pipeline", ValueFromPipeLine = $true, Position = 0)]
        [Hashtable]$Obj
    )

    process {
        # If a hash is passed then recall this function with the hash splatted instead.
        if ($null -ne $Obj) {
            return Write-PlasterManifestContent @obj
        }

        # Update the element based on the type
        switch ($ContentType) {
            'File' {
                Write-PlasterManifestContentFile -Source $Source -Destination $Destination -Condition $Condition -OpenInEditor $OpenInEditor
            }
            'TemplateFile' {
                Write-PlasterManifestContentTemplateFile -Source $Source -Destination $Destination -Condition $Condition -OpenInEditor $OpenInEditor -Encoding $Encoding
            }
            'Message' {
                Write-PlasterManifestContentMessage -Message $Message -Condition $Condition -NoNewLine $NoNewLine
            }
            'Modify' {
                $MSplat = @{
                    Path = $Path
                    Condition = $Condition
                    Encoding = $Encoding
                    Original = $Original
                    OriginalExpand = $OriginalExpand
                    Substitute = $Substitute
                    SubstituteExpand = $SubstituteExpand
                    ReplaceCondition = $ReplaceCondition
                }
                Write-PlasterManifestContentModify @MSplat
            }
            'newModuleManifest' {
                $NMMSplat = @{}
                $ValidParams = @(
                    'Destination',
                    'Condition',
                    'OpenInEditor',
                    'Encoding',
                    'author',
                    'companyName',
                    'description',
                    'moduleVersion',
                    'rootModule',
                    'copyright',
                    'tags',
                    'projectUri',
                    'licenseUri',
                    'iconUri',
                    'helpInfoUri',
                    'nestedModules',
                    'requiredModules',
                    'typesToProcess',
                    'formatsToProcess',
                    'scriptsToProcess',
                    'requiredAssemblies',
                    'fileList',
                    'moduleList',
                    'functionsToExport',
                    'aliasesToExport',
                    'variablesToExport',
                    'cmdletsToExport',
                    'dscResourcesToExport',
                    'compatiblePSEditions',
                    'defaultCommandPrefix'
                )

                $MyParams = $PSCmdlet.MyInvocation.BoundParameters
                $MyParams.Keys | Where-Object {$ValidParams -contains $_} | ForEach-Object {
                    $NMMSplat[$_] = $MyParams[$_]
                }
                Write-PlasterManifestContentNewModuleManifest @NMMSplat
            }
            'requireModule' {
                $RMSplat = @{
                    Name = $Name
                    Condition = $Condition
                    MinimumVersion = $MinimumVersion
                    MaximumVersion = $MaximumVersion
                    RequiredVersion = $RequiredVersion
                    Message = $Message
                }
                Write-PlasterManifestContentRequireModule @RMSplat
            }
        }
    }
}
