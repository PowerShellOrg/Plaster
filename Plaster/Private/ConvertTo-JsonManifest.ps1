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
                InputObject = $jsonObject
                Depth = 10
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
