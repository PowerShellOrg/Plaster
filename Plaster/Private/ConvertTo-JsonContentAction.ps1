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
