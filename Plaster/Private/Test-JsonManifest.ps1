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
