#Requires -Version 5.1

using namespace System.Management.Automation

<#
.SYNOPSIS
    JSON manifest handling for Plaster 2.0

.DESCRIPTION
    This module provides JSON manifest support for Plaster templates,
    including validation, conversion, and processing capabilities.
#>

# JSON Schema validation function
function Test-JsonManifest {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$JsonContent,

        [Parameter()]
        [string]$SchemaPath,

        [Parameter()]
        [switch]$Detailed
    )

    begin {
        Write-PlasterLog -Level Debug -Message "Starting JSON manifest validation"

        # Default schema path
        if (-not $SchemaPath) {
            $SchemaPath = Join-Path $PSScriptRoot "..\schema\plaster-manifest-v2.json"
        }
    }

    process {
        try {
            # Parse JSON content
            $jsonObject = $JsonContent | ConvertFrom-Json -ErrorAction Stop

            # Basic structure validation
            $requiredProperties = @('schemaVersion', 'metadata', 'content')
            foreach ($property in $requiredProperties) {
                if (-not $jsonObject.PSObject.Properties[$property]) {
                    throw "Missing required property: $property"
                }
            }

            # Schema version validation
            if ($jsonObject.schemaVersion -ne '2.0') {
                throw "Unsupported schema version: $($jsonObject.schemaVersion). Expected: 2.0"
            }

            # Metadata validation
            $metadata = $jsonObject.metadata
            $requiredMetadata = @('name', 'id', 'version', 'title', 'author')
            foreach ($property in $requiredMetadata) {
                if (-not $metadata.PSObject.Properties[$property] -or [string]::IsNullOrWhiteSpace($metadata.$property)) {
                    throw "Missing or empty required metadata property: $property"
                }
            }

            # Validate GUID format for ID
            try {
                [Guid]::Parse($metadata.id) | Out-Null
            } catch {
                throw "Invalid GUID format for metadata.id: $($metadata.id)"
            }

            # Validate semantic version format
            if ($metadata.version -notmatch '^\d+\.\d+\.\d+([+-].*)?$') {
                throw "Invalid version format: $($metadata.version). Expected semantic versioning (e.g., 1.0.0)"
            }

            # Validate template name pattern
            if ($metadata.name -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
                throw "Invalid template name: $($metadata.name). Must start with letter and contain only letters, numbers, underscore, or hyphen"
            }

            # Parameters validation
            # Parameters validation
            if ($jsonObject.PSObject.Properties['parameters'] -and $jsonObject.parameters -and $jsonObject.parameters.Count -gt 0) {
                Test-JsonManifestParameters -Parameters $jsonObject.parameters
            }

            # Content validation
            # Content validation
            # Content validation
            if ($jsonObject.content -and $jsonObject.content.Count -gt 0) {
                Test-JsonManifestContent -Content $jsonObject.content
            } else {
                throw "Content section cannot be empty"
            }

            Write-PlasterLog -Level Debug -Message "JSON manifest validation successful"
            return $true
        } catch {
            $errorMessage = "JSON manifest validation failed: $($_.Exception.Message)"
            Write-PlasterLog -Level Error -Message $errorMessage

            if ($Detailed) {
                throw $_
            }

            return $false
        }
    }
}

# Validate parameters section
function Test-JsonManifestParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Parameters
    )

    $parameterNames = @()

    foreach ($param in $Parameters) {
        # Required properties
        if (-not $param.name -or -not $param.type) {
            throw "Parameter missing required 'name' or 'type' property"
        }

        # Validate parameter name pattern
        if ($param.name -notmatch '^[A-Za-z][A-Za-z0-9_]*$') {
            throw "Invalid parameter name: $($param.name). Must start with letter and contain only letters, numbers, or underscore"
        }

        # Check for duplicate parameter names
        if ($param.name -in $parameterNames) {
            throw "Duplicate parameter name: $($param.name)"
        }
        $parameterNames += $param.name

        # Validate parameter type
        $validTypes = @('text', 'user-fullname', 'user-email', 'choice', 'multichoice', 'switch')
        if ($param.type -notin $validTypes) {
            throw "Invalid parameter type: $($param.type). Valid types: $($validTypes -join ', ')"
        }

        # Choice parameters must have choices
        if ($param.type -in @('choice', 'multichoice') -and -not $param.choices) {
            throw "Parameter '$($param.name)' of type '$($param.type)' must have 'choices' property"
        }

        # Validate choices if present
        if ($param.choices) {
            foreach ($choice in $param.choices) {
                if (-not $choice.label -or -not $choice.value) {
                    throw "Choice in parameter '$($param.name)' missing required 'label' or 'value' property"
                }
            }
        }

        # Validate dependsOn references
        if ($param.dependsOn) {
            foreach ($dependency in $param.dependsOn) {
                if ($dependency -notin $parameterNames -and $dependency -ne $param.name) {
                    # Note: We'll validate this after processing all parameters
                    Write-PlasterLog -Level Debug -Message "Parameter '$($param.name)' depends on '$dependency'"
                }
            }
        }

        # Validate condition syntax if present
        if ($param.condition) {
            Test-PlasterCondition -Condition $param.condition -ParameterName $param.name
        }
    }
}

# Validate content section
function Test-JsonManifestContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Content
    )

    if ($Content.Count -eq 0) {
        throw "Content section cannot be empty"
    }

    foreach ($action in $Content) {
        if (-not $action.type) {
            throw "Content action missing required 'type' property"
        }

        # Validate action type and required properties
        switch ($action.type) {
            'message' {
                if (-not $action.text) {
                    throw "Message action missing required 'text' property"
                }
            }
            'file' {
                if (-not $action.source -or -not $action.destination) {
                    throw "File action missing required 'source' or 'destination' property"
                }
            }
            'templateFile' {
                if (-not $action.source -or -not $action.destination) {
                    throw "TemplateFile action missing required 'source' or 'destination' property"
                }
            }
            'directory' {
                if (-not $action.destination) {
                    throw "Directory action missing required 'destination' property"
                }
            }
            'newModuleManifest' {
                if (-not $action.destination) {
                    throw "NewModuleManifest action missing required 'destination' property"
                }
            }
            'modify' {
                if (-not $action.path -or -not $action.modifications) {
                    throw "Modify action missing required 'path' or 'modifications' property"
                }

                # Validate modifications
                foreach ($modification in $action.modifications) {
                    if (-not $modification.type) {
                        throw "Modification missing required 'type' property"
                    }

                    if ($modification.type -eq 'replace') {
                        if (-not $modification.PSObject.Properties['search'] -or -not $modification.PSObject.Properties['replace']) {
                            throw "Replace modification missing required 'search' or 'replace' property"
                        }
                    }
                }
            }
            'requireModule' {
                if (-not $action.name) {
                    throw "RequireModule action missing required 'name' property"
                }
            }
            'execute' {
                if (-not $action.script) {
                    throw "Execute action missing required 'script' property"
                }
            }
            default {
                throw "Unknown content action type: $($action.type)"
            }
        }

        # Validate condition if present
        if ($action.condition) {
            Test-PlasterCondition -Condition $action.condition -Context "Content action ($($action.type))"
        }
    }
}

# Convert JSON manifest to internal Plaster format
function ConvertFrom-JsonManifest {
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$JsonContent,

        [Parameter()]
        [switch]$Validate = $true
    )

    begin {
        Write-PlasterLog -Level Debug -Message "Converting JSON manifest to internal format"
    }

    process {
        try {
            # Validate JSON if requested
            if ($Validate) {
                $isValid = Test-JsonManifest -JsonContent $JsonContent -Detailed
                if (-not $isValid) {
                    throw "JSON manifest validation failed"
                }
            }

            # Parse JSON
            $jsonObject = $JsonContent | ConvertFrom-Json

            # Create XML document
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml('<?xml version="1.0" encoding="utf-8"?><plasterManifest xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1"></plasterManifest>')

            $manifest = $xmlDoc.DocumentElement
            $manifest.SetAttribute('schemaVersion', '1.2')  # Use XML schema version for compatibility

            if ($jsonObject.metadata.templateType) {
                $manifest.SetAttribute('templateType', $jsonObject.metadata.templateType)
            }

            # Add metadata
            $metadataElement = $xmlDoc.CreateElement('metadata', $TargetNamespace)
            $manifest.AppendChild($metadataElement)

            # Add metadata properties
            $metadataProperties = @('name', 'id', 'version', 'title', 'description', 'author', 'tags')
            foreach ($property in $metadataProperties) {
                if ($jsonObject.metadata.PSObject.Properties[$property]) {
                    $element = $xmlDoc.CreateElement($property, $TargetNamespace)
                    $value = $jsonObject.metadata.$property

                    if ($property -eq 'tags' -and $value -is [array]) {
                        $element.InnerText = $value -join ', '
                    } else {
                        $element.InnerText = $value
                    }
                    $metadataElement.AppendChild($element)
                }
            }

            # Add parameters
            $parametersElement = $xmlDoc.CreateElement('parameters', $TargetNamespace)
            $manifest.AppendChild($parametersElement)

            if ($jsonObject.parameters) {
                foreach ($param in $jsonObject.parameters) {
                    $paramElement = $xmlDoc.CreateElement('parameter', $TargetNamespace)
                    $paramElement.SetAttribute('name', $param.name)
                    $paramElement.SetAttribute('type', $param.type)

                    if ($param.prompt) {
                        $paramElement.SetAttribute('prompt', $param.prompt)
                    }

                    if ($param.default) {
                        if ($param.default -is [array]) {
                            $paramElement.SetAttribute('default', ($param.default -join ','))
                        } else {
                            $paramElement.SetAttribute('default', $param.default)
                        }
                    }

                    if ($param.condition) {
                        $paramElement.SetAttribute('condition', $param.condition)
                    }

                    if ($param.store) {
                        $paramElement.SetAttribute('store', $param.store)
                    }

                    # Add choices for choice/multichoice parameters
                    if ($param.choices) {
                        foreach ($choice in $param.choices) {
                            $choiceElement = $xmlDoc.CreateElement('choice', $TargetNamespace)
                            $choiceElement.SetAttribute('label', $choice.label)
                            $choiceElement.SetAttribute('value', $choice.value)

                            if ($choice.help) {
                                $choiceElement.SetAttribute('help', $choice.help)
                            }

                            $paramElement.AppendChild($choiceElement)
                        }
                    }

                    $parametersElement.AppendChild($paramElement)
                }
            }

            # Add content
            $contentElement = $xmlDoc.CreateElement('content', $TargetNamespace)
            $manifest.AppendChild($contentElement)

            foreach ($action in $jsonObject.content) {
                $actionElement = ConvertFrom-JsonContentAction -Action $action -XmlDocument $xmlDoc
                $contentElement.AppendChild($actionElement)
            }

            Write-PlasterLog -Level Debug -Message "JSON to XML conversion completed successfully"
            return $xmlDoc
        } catch {
            $errorMessage = "Failed to convert JSON manifest: $($_.Exception.Message)"
            Write-PlasterLog -Level Error -Message $errorMessage
            throw $_
        }
    }
}

# Convert JSON content action to XML element
function ConvertFrom-JsonContentAction {
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param(
        [Parameter(Mandatory)]
        [object]$Action,

        [Parameter(Mandatory)]
        [System.Xml.XmlDocument]$XmlDocument
    )

    switch ($Action.type) {
        'message' {
            $element = $XmlDocument.CreateElement('message', $TargetNamespace)
            $element.InnerText = $Action.text

            if ($Action.noNewline) {
                $element.SetAttribute('nonewline', 'true')
            }
        }
        'file' {
            $element = $XmlDocument.CreateElement('file', $TargetNamespace)
            $element.SetAttribute('source', $Action.source)
            $element.SetAttribute('destination', $Action.destination)

            if ($Action.encoding) {
                $element.SetAttribute('encoding', $Action.encoding)
            }

            if ($Action.openInEditor) {
                $element.SetAttribute('openInEditor', 'true')
            }
        }
        'templateFile' {
            $element = $XmlDocument.CreateElement('templateFile', $TargetNamespace)
            $element.SetAttribute('source', $Action.source)
            $element.SetAttribute('destination', $Action.destination)

            if ($Action.encoding) {
                $element.SetAttribute('encoding', $Action.encoding)
            }

            if ($Action.openInEditor) {
                $element.SetAttribute('openInEditor', 'true')
            }
        }
        'directory' {
            $element = $XmlDocument.CreateElement('file', $TargetNamespace)
            $element.SetAttribute('source', '')
            $element.SetAttribute('destination', $Action.destination)
        }
        'newModuleManifest' {
            $element = $XmlDocument.CreateElement('newModuleManifest', $TargetNamespace)
            $element.SetAttribute('destination', $Action.destination)

            $manifestProperties = @('moduleVersion', 'rootModule', 'author', 'companyName', 'description', 'powerShellVersion', 'copyright', 'encoding')
            foreach ($property in $manifestProperties) {
                if ($Action.PSObject.Properties[$property]) {
                    $element.SetAttribute($property, $Action.$property)
                }
            }

            if ($Action.openInEditor) {
                $element.SetAttribute('openInEditor', 'true')
            }
        }
        'modify' {
            $element = $XmlDocument.CreateElement('modify', $TargetNamespace)
            $element.SetAttribute('path', $Action.path)

            if ($Action.encoding) {
                $element.SetAttribute('encoding', $Action.encoding)
            }

            # Add modifications
            foreach ($modification in $Action.modifications) {
                if ($modification.type -eq 'replace') {
                    $replaceElement = $XmlDocument.CreateElement('replace', $TargetNamespace)

                    $originalElement = $XmlDocument.CreateElement('original', $TargetNamespace)
                    $originalElement.InnerText = $modification.search
                    if ($modification.isRegex) {
                        $originalElement.SetAttribute('expand', 'true')
                    }
                    $replaceElement.AppendChild($originalElement)

                    $substituteElement = $XmlDocument.CreateElement('substitute', $TargetNamespace)
                    $substituteElement.InnerText = $modification.replace
                    $substituteElement.SetAttribute('expand', 'true')
                    $replaceElement.AppendChild($substituteElement)

                    if ($modification.condition) {
                        $replaceElement.SetAttribute('condition', $modification.condition)
                    }

                    $element.AppendChild($replaceElement)
                }
            }
        }
        'requireModule' {
            $element = $XmlDocument.CreateElement('requireModule', $TargetNamespace)
            $element.SetAttribute('name', $Action.name)

            $moduleProperties = @('minimumVersion', 'maximumVersion', 'requiredVersion', 'message')
            foreach ($property in $moduleProperties) {
                if ($Action.PSObject.Properties[$property]) {
                    $element.SetAttribute($property, $Action.$property)
                }
            }
        }
        'execute' {
            # Execute action doesn't have direct XML equivalent, convert to message with warning
            $element = $XmlDocument.CreateElement('message', $TargetNamespace)
            $element.InnerText = "Warning: Execute action not supported in XML format. Script: $($Action.script)"
            Write-PlasterLog -Level Warning -Message "Execute action converted to message - not supported in XML format"
        }
        default {
            throw "Unknown action type: $($Action.type)"
        }
    }

    # Add condition if present
    if ($Action.condition) {
        $element.SetAttribute('condition', $Action.condition)
    }

    return $element
}

# Convert XML manifest to JSON format
function ConvertTo-JsonManifest {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Xml.XmlDocument]$XmlManifest,

        [Parameter()]
        [switch]$Compress
    )

    begin {
        Write-PlasterLog -Level Debug -Message "Converting XML manifest to JSON format"
    }

    process {
        try {
            $jsonObject = [ordered]@{
                '$schema'       = 'https://raw.githubusercontent.com/PowerShellOrg/Plaster/v2/schema/plaster-manifest-v2.json'
                'schemaVersion' = '2.0'
            }

            # Extract metadata
            $metadata = [ordered]@{}
            $metadataNode = $XmlManifest.plasterManifest.metadata

            if ($metadataNode) {
                foreach ($child in $metadataNode.ChildNodes) {
                    if ($child.NodeType -eq 'Element') {
                        $value = $child.InnerText
                        if ($child.LocalName -eq 'tags' -and $value) {
                            $metadata[$child.LocalName] = $value -split ',' | ForEach-Object { $_.Trim() }
                        } else {
                            $metadata[$child.LocalName] = $value
                        }
                    }
                }
            }

            # Add template type if present
            if ($XmlManifest.plasterManifest.templateType) {
                $metadata['templateType'] = $XmlManifest.plasterManifest.templateType
            } else {
                $metadata['templateType'] = 'Project'
            }

            $jsonObject['metadata'] = $metadata

            # Extract parameters
            $parameters = @()
            $parametersNode = $XmlManifest.plasterManifest.parameters

            if ($parametersNode) {
                foreach ($paramNode in $parametersNode.ChildNodes) {
                    if ($paramNode.NodeType -eq 'Element' -and $paramNode.LocalName -eq 'parameter') {
                        $param = [ordered]@{
                            'name' = $paramNode.name
                            'type' = $paramNode.type
                        }

                        if ($paramNode.prompt) {
                            $param['prompt'] = $paramNode.prompt
                        }

                        if ($paramNode.default) {
                            if ($paramNode.type -eq 'multichoice') {
                                $param['default'] = $paramNode.default -split ','
                            } else {
                                $param['default'] = $paramNode.default
                            }
                        }

                        if ($paramNode.condition) {
                            $param['condition'] = $paramNode.condition
                        }

                        if ($paramNode.store) {
                            $param['store'] = $paramNode.store
                        }

                        # Extract choices
                        $choices = @()
                        foreach ($choiceNode in $paramNode.ChildNodes) {
                            if ($choiceNode.NodeType -eq 'Element' -and $choiceNode.LocalName -eq 'choice') {
                                $choice = [ordered]@{
                                    'label' = $choiceNode.label
                                    'value' = $choiceNode.value
                                }

                                if ($choiceNode.help) {
                                    $choice['help'] = $choiceNode.help
                                }

                                $choices += $choice
                            }
                        }

                        if ($choices.Count -gt 0) {
                            $param['choices'] = $choices
                        }

                        $parameters += $param
                    }
                }
            }

            if ($parameters.Count -gt 0) {
                $jsonObject['parameters'] = $parameters
            }

            # Extract content
            $content = @()
            $contentNode = $XmlManifest.plasterManifest.content

            if ($contentNode) {
                foreach ($actionNode in $contentNode.ChildNodes) {
                    if ($actionNode.NodeType -eq 'Element') {
                        $action = ConvertTo-JsonContentAction -ActionNode $actionNode
                        if ($action) {
                            $content += $action
                        }
                    }
                }
            }

            $jsonObject['content'] = $content

            # Convert to JSON
            $jsonParams = @{
                InputObject = $jsonObject
                Depth       = 10
            }

            if (-not $Compress) {
                $jsonParams['Compress'] = $false
            }

            $jsonResult = $jsonObject | ConvertTo-Json @jsonParams

            Write-PlasterLog -Level Debug -Message "XML to JSON conversion completed successfully"
            return $jsonResult
        } catch {
            $errorMessage = "Failed to convert XML manifest to JSON: $($_.Exception.Message)"
            Write-PlasterLog -Level Error -Message $errorMessage
            throw $_
        }
    }
}

# Convert XML content action to JSON object
function ConvertTo-JsonContentAction {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [System.Xml.XmlElement]$ActionNode
    )

    $action = [ordered]@{
        'type' = $ActionNode.LocalName
    }

    switch ($ActionNode.LocalName) {
        'message' {
            $action['text'] = $ActionNode.InnerText
            if ($ActionNode.nonewline -eq 'true') {
                $action['noNewline'] = $true
            }
        }
        'file' {
            $action['source'] = $ActionNode.source
            $action['destination'] = $ActionNode.destination

            if ($ActionNode.encoding) {
                $action['encoding'] = $ActionNode.encoding
            }

            if ($ActionNode.openInEditor -eq 'true') {
                $action['openInEditor'] = $true
            }

            # Handle directory creation (empty source)
            if ([string]::IsNullOrEmpty($ActionNode.source)) {
                $action['type'] = 'directory'
                $action.Remove('source')
            }
        }
        'templateFile' {
            $action['source'] = $ActionNode.source
            $action['destination'] = $ActionNode.destination

            if ($ActionNode.encoding) {
                $action['encoding'] = $ActionNode.encoding
            }

            if ($ActionNode.openInEditor -eq 'true') {
                $action['openInEditor'] = $true
            }
        }
        'newModuleManifest' {
            $action['destination'] = $ActionNode.destination

            $manifestProperties = @('moduleVersion', 'rootModule', 'author', 'companyName', 'description', 'powerShellVersion', 'copyright', 'encoding')
            foreach ($property in $manifestProperties) {
                if ($ActionNode.$property) {
                    $action[$property] = $ActionNode.$property
                }
            }

            if ($ActionNode.openInEditor -eq 'true') {
                $action['openInEditor'] = $true
            }
        }
        'modify' {
            $action['path'] = $ActionNode.path

            if ($ActionNode.encoding) {
                $action['encoding'] = $ActionNode.encoding
            }

            # Extract modifications
            $modifications = @()
            foreach ($child in $ActionNode.ChildNodes) {
                if ($child.NodeType -eq 'Element' -and $child.LocalName -eq 'replace') {
                    $modification = [ordered]@{
                        'type' = 'replace'
                    }

                    $originalNode = $child.SelectSingleNode('*[local-name()="original"]')
                    $substituteNode = $child.SelectSingleNode('*[local-name()="substitute"]')

                    if ($originalNode) {
                        $modification['search'] = $originalNode.InnerText
                        if ($originalNode.expand -eq 'true') {
                            $modification['isRegex'] = $true
                        }
                    }

                    if ($substituteNode) {
                        $modification['replace'] = $substituteNode.InnerText
                    }

                    if ($child.condition) {
                        $modification['condition'] = $child.condition
                    }

                    $modifications += $modification
                }
            }

            $action['modifications'] = $modifications
        }
        'requireModule' {
            $action['name'] = $ActionNode.name

            $moduleProperties = @('minimumVersion', 'maximumVersion', 'requiredVersion', 'message')
            foreach ($property in $moduleProperties) {
                if ($ActionNode.$property) {
                    $action[$property] = $ActionNode.$property
                }
            }
        }
        default {
            Write-PlasterLog -Level Warning -Message "Unknown XML action type: $($ActionNode.LocalName)"
            return $null
        }
    }

    # Add condition if present
    if ($ActionNode.condition) {
        $action['condition'] = $ActionNode.condition
    }

    return $action
}

# Test Plaster condition syntax
function Test-PlasterCondition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Condition,

        [Parameter()]
        [string]$ParameterName,

        [Parameter()]
        [string]$Context = 'condition'
    )

    try {
        # Basic syntax validation - ensure it's valid PowerShell
        $tokens = $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($Condition, [ref]$tokens, [ref]$errors)

        if ($errors.Count -gt 0) {
            $errorMsg = if ($ParameterName) {
                "Invalid condition in parameter '$ParameterName': $($errors[0].Message)"
            } else {
                "Invalid condition in ${Context}: $($errors[0].Message)"
            }
            throw $errorMsg
        }

        Write-PlasterLog -Level Debug -Message "Condition validation passed: $Condition"
        return $true
    } catch {
        Write-PlasterLog -Level Error -Message "Condition validation failed: $($_.Exception.Message)"
        throw $_
    }
}

# Get manifest type (XML or JSON)
function Get-PlasterManifestType {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Manifest file not found: $ManifestPath"
    }

    $content = Get-Content -LiteralPath $ManifestPath -Raw -ErrorAction Stop

    # Check for JSON format
    if ($content.TrimStart() -match '^[\s]*[\{\[]') {
        try {
            $jsonObject = $content | ConvertFrom-Json -ErrorAction Stop
            if ($jsonObject.schemaVersion -eq '2.0') {
                return 'JSON'
            }
        } catch {
            # Not valid JSON, might be XML
        }
    }

    # Check for XML format
    if ($content.TrimStart() -match '^[\s]*<\?xml' -or $content -match '<plasterManifest') {
        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml($content)
            return 'XML'
        } catch {
            # Not valid XML either
        }
    }

    throw "Unable to determine manifest format. File must be valid XML or JSON."
}
# Add this function to support New-PlasterManifest
function New-JsonManifestStructure {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,

        [Parameter(Mandatory)]
        [string]$TemplateType,

        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter()]
        [string]$TemplateVersion = "1.0.0",

        [Parameter()]
        [string]$Title = $TemplateName,

        [Parameter()]
        [string]$Description = "",

        [Parameter()]
        [string]$Author = "",

        [Parameter()]
        [string[]]$Tags = @()
    )

    $manifest = [ordered]@{
        '$schema'       = 'https://raw.githubusercontent.com/PowerShellOrg/Plaster/v2/schema/plaster-manifest-v2.json'
        'schemaVersion' = '2.0'
        'metadata'      = [ordered]@{
            'name'         = $TemplateName
            'id'           = $Id
            'version'      = $TemplateVersion
            'title'        = $Title
            'description'  = $Description
            'author'       = $Author
            'templateType' = $TemplateType
        }
        'parameters'    = @()
        'content'       = @()
    }

    if ($Tags.Count -gt 0) {
        $manifest.metadata['tags'] = $Tags
    }

    return $manifest
}
function Get-PlasterManifestType {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Manifest file not found: $ManifestPath"
    }

    try {
        $content = Get-Content -LiteralPath $ManifestPath -Raw -ErrorAction Stop

        # Check file extension first
        $extension = [System.IO.Path]::GetExtension($ManifestPath).ToLower()
        if ($extension -eq '.json') {
            # Validate it's actually JSON
            try {
                $jsonObject = $content | ConvertFrom-Json -ErrorAction Stop
                # Check for Plaster 2.0 JSON schema
                if ($jsonObject.schemaVersion -eq '2.0') {
                    return 'JSON'
                }
                # Also accept older JSON formats without strict version check
                if ($jsonObject.PSObject.Properties['metadata'] -and $jsonObject.PSObject.Properties['content']) {
                    return 'JSON'
                }
            } catch {
                throw "File has .json extension but contains invalid JSON: $($_.Exception.Message)"
            }
        } elseif ($extension -eq '.xml') {
            # Validate it's actually XML
            try {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $xmlDoc.LoadXml($content)
                if ($xmlDoc.DocumentElement.LocalName -eq 'plasterManifest') {
                    return 'XML'
                }
            } catch {
                throw "File has .xml extension but contains invalid XML: $($_.Exception.Message)"
            }
        }

        # If no extension or ambiguous, try to detect by content
        $trimmedContent = $content.TrimStart()

        # Check for JSON format (starts with { or [)
        if ($trimmedContent -match '^[\s]*[\{\[]') {
            try {
                $jsonObject = $content | ConvertFrom-Json -ErrorAction Stop
                # Validate it's a Plaster JSON manifest
                if ($jsonObject.PSObject.Properties['metadata'] -and $jsonObject.PSObject.Properties['content']) {
                    return 'JSON'
                }
            } catch {
                # Not valid JSON, continue to XML check
            }
        }

        # Check for XML format
        if ($trimmedContent -match '^[\s]*<\?xml' -or $trimmedContent -match '<plasterManifest') {
            try {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $xmlDoc.LoadXml($content)
                if ($xmlDoc.DocumentElement.LocalName -eq 'plasterManifest') {
                    return 'XML'
                }
            } catch {
                # Not valid XML
            }
        }

        throw "Unable to determine manifest format. File must be valid XML or JSON."
    } catch {
        throw "Error determining manifest type for '$ManifestPath': $($_.Exception.Message)"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-JsonManifest'
    'ConvertFrom-JsonManifest'
    'ConvertTo-JsonManifest'
    'Get-PlasterManifestType'
    'New-JsonManifestStructure'
)