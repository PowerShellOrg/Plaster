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
                    [void]$replaceElement.AppendChild($originalElement)

                    $substituteElement = $XmlDocument.CreateElement('substitute', $TargetNamespace)
                    $substituteElement.InnerText = $modification.replace
                    $substituteElement.SetAttribute('expand', 'true')
                    [void]$replaceElement.AppendChild($substituteElement)

                    if ($modification.condition) {
                        $replaceElement.SetAttribute('condition', $modification.condition)
                    }

                    [void]$element.AppendChild($replaceElement)
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
