function New-PlasterManifest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$pwd\plasterManifest.xml",

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9a-zA-Z_-]+$')]
        [string]
        $TemplateName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Item', 'Project')]
        [string]
        $TemplateType,

        [Parameter()]
        [Guid]
        $Id = [guid]::NewGuid(),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d+\.\d+(\.\d+((\.\d+|(\+|-).*)?)?)?$')]
        [string]
        $TemplateVersion = "1.0.0",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Title = $TemplateName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [string[]]
        $Tags,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        [Parameter()]
        [switch]
        $AddContent
    )

    begin {
        $PlasterManifestInfo = [PSCustomObject]@{
            name        = $TemplateName
            id          = $Id
            title       = $title
            version     = $TemplateVersion
            author      = $Author
            description = $Description
            tags        = $Tags
        }
        $PlasterManifestInfo | ConvertTo-Json | out-file plasterManifest.json  
    }