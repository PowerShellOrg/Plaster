function ConvertTo-JsonManifest {
    <#
    .SYNOPSIS
        Converts a Plaster XML manifest to JSON format.

    .DESCRIPTION
        Converts an XML-format Plaster manifest (plasterManifest.xml) to the JSON format
        (plasterManifest.json) used by Plaster 2.0. Accepts an XmlDocument from
        Test-PlasterManifest via the pipeline or the -XmlManifest parameter and returns
        the resulting JSON as a string.

    .PARAMETER XmlManifest
        The parsed XML manifest to convert. Use Test-PlasterManifest to load and validate
        a plasterManifest.xml file before passing it to this function.

    .PARAMETER Compress
        Omits white space and indented formatting in the output JSON string.

    .EXAMPLE
        $xml = Test-PlasterManifest -Path .\plasterManifest.xml
        ConvertTo-JsonManifest -XmlManifest $xml | Set-Content .\plasterManifest.json

        Converts plasterManifest.xml and writes the result to plasterManifest.json.

    .EXAMPLE
        Test-PlasterManifest -Path .\plasterManifest.xml | ConvertTo-JsonManifest | Set-Content .\plasterManifest.json

        Pipes the validated manifest directly into ConvertTo-JsonManifest.

    .INPUTS
        System.Xml.XmlDocument

    .OUTPUTS
        System.String

    .LINK
        Test-PlasterManifest
    #>
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
                '$schema' = 'https://raw.githubusercontent.com/PowerShellOrg/Plaster/v2/schema/plaster-manifest-v2.json'
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
                Depth = 10
            }

            if ($Compress) {
                $jsonParams['Compress'] = $true
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
