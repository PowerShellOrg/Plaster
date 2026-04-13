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
        '$schema' = 'https://raw.githubusercontent.com/PowerShellOrg/Plaster/v2/schema/plaster-manifest-v2.json'
        'schemaVersion' = '2.0'
        'metadata' = [ordered]@{
            'name' = $TemplateName
            'id' = $Id
            'version' = $TemplateVersion
            'title' = $Title
            'description' = $Description
            'author' = $Author
            'templateType' = $TemplateType
        }
        'parameters' = @()
        'content' = @()
    }

    if ($Tags.Count -gt 0) {
        $manifest.metadata['tags'] = $Tags
    }

    return $manifest
}
