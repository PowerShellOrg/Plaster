function New-PlasterManifest {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$pwd\plasterManifest.xml",

        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[0-9a-zA-Z_-]+$')]
        [string]
        $TemplateName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Item','Project')]
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
        $AddContent,

        [Parameter()]
        [string[]]
        $Parameters,

        [Parameter()]
        [string[]]
        $Content
    )

    begin {
        $resolvedPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($Path)

        $caseCorrectedTemplateType = [System.Char]::ToUpper($TemplateType[0]) + $TemplateType.Substring(1).ToLower()

        $manifestStr = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="$LatestSupportedSchemaVersion"
                 templateType="$caseCorrectedTemplateType"
                 xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">

    <metadata>
        <name></name>
        <id></id>
        <version></version>
        <title></title>
        <description></description>
        <author></author>
        <tags></tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@
    }

    end {
        $manifest = [xml]$manifestStr

        # Set via .innerText to get .NET to encode special XML chars as entity references.
        $manifest.plasterManifest.metadata["name"].innerText = "$TemplateName"
        $manifest.plasterManifest.metadata["id"].innerText = "$Id"
        $manifest.plasterManifest.metadata["version"].innerText = "$TemplateVersion"
        $manifest.plasterManifest.metadata["title"].innerText = "$Title"
        $manifest.plasterManifest.metadata["description"].innerText = "$Description"
        $manifest.plasterManifest.metadata["author"].innerText = "$Author"

        $OFS = ", "
        $manifest.plasterManifest.metadata["tags"].innerText = "$Tags"

        if ($AddContent) {
            $baseDir = Split-Path $Path -Parent
            $filenames = Get-ChildItem $baseDir -Recurse -File -Name
            foreach ($filename in $filenames) {
                if ($filename -match "plasterManifest.*\.xml") {
                    continue
                }

                $fileElem = $manifest.CreateElement('file', $TargetNamespace)

                $srcAttr = $manifest.CreateAttribute("source")
                $srcAttr.Value = $filename
                $null = $fileElem.Attributes.Append($srcAttr)

                $dstAttr = $manifest.CreateAttribute("destination")
                $dstAttr.Value = $filename
                $null = $fileElem.Attributes.Append($dstAttr)

                $null = $manifest.plasterManifest["content"].AppendChild($fileElem)
            }
        }
        else {
            # If we passed some parameter xml then assign it
            if (-not [string]::IsNullOrEmpty($Parameters)) {
                $null = $manifest.plasterManifest["parameters"].InnerXML = ($Parameters -join '')
            }
            # If we passed some content xml then assign it
            if (-not [string]::IsNullOrEmpty($Content)) {
                $null = $manifest.plasterManifest["content"].InnerXML = ($Content -join '')
            }
        }

        # This configures the XmlWriter to put attributes on a new line
        $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
        $xmlWriterSettings.Indent = $true
        $xmlWriterSettings.NewLineOnAttributes = $true

        try {
            if ($PSCmdlet.ShouldProcess($resolvedPath, $LocalizedData.ShouldCreateNewPlasterManifest)) {
                $xmlWriter = [System.Xml.XmlWriter]::Create($resolvedPath, $xmlWriterSettings)
                $manifest.Save($xmlWriter)
            }
        }
        finally {
            if ($xmlWriter) {
                $xmlWriter.Dispose()
            }
        }
    }
}
