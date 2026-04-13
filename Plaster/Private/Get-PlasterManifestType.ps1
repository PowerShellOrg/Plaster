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
