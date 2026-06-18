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
            [void]$manifest.AppendChild($metadataElement)

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
                    [void]$metadataElement.AppendChild($element)
                }
            }

            # Add parameters
            $parametersElement = $xmlDoc.CreateElement('parameters', $TargetNamespace)
            [void]$manifest.AppendChild($parametersElement)

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

                            [void]$paramElement.AppendChild($choiceElement)
                        }
                    }

                    [void]$parametersElement.AppendChild($paramElement)
                }
            }

            # Add content
            $contentElement = $xmlDoc.CreateElement('content', $TargetNamespace)
            [void]$manifest.AppendChild($contentElement)

            foreach ($action in $jsonObject.content) {
                $actionElement = ConvertFrom-JsonContentAction -Action $action -XmlDocument $xmlDoc
                [void]$contentElement.AppendChild($actionElement)
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
