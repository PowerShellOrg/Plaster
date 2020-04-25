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
        [PSObject]
        $AddContentFromObject,

        [Parameter()]
        [PSObject]
        $AddParametersFromObject

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
                $fileElem.Attributes.Append($srcAttr) > $null

                $dstAttr = $manifest.CreateAttribute("destination")
                $dstAttr.Value = $filename
                $fileElem.Attributes.Append($dstAttr) > $null

                $manifest.plasterManifest["content"].AppendChild($fileElem) > $null
            }
        }

        if ($AddParametersFromObject) {
            foreach ($Parameter in $AddParametersFromObject) {
                Write-Verbose " a "
                $ParameterElem = $manifest.CreateElement('Parameter', $TargetNamespace)

                ForEach ($ParamNum in $(1..$($Parameter.count))) {
                    if ($([PSObject]$Parameter.keys)[$($ParamNum - 1)] -eq 'choices') {
                        $Choices = $($([PSObject]$Parameter.values)[$($ParamNum - 1)])
                        ForEach ($Choice in $choices) {
                            $ChoiceElem = $manifest.CreateElement('choice', $TargetNamespace)
                            ForEach ($ChoiceNum in $(1..$($choice.count))) { 
                                $ChoiceAtrr = $manifest.CreateAttribute($($([PSObject]$Choice.keys)[$($ChoiceNum - 1)]))
                                $ChoiceAtrr.value = $($([PSObject]$Choice.values)[$($ChoiceNum - 1)])
                                $ChoiceElem.Attributes.Append($ChoiceAtrr) > $null
                            }                            
                            $ParameterElem.AppendChild($ChoiceElem) > $Null
                        }
                    } Else {
                        $ParamAttr = $manifest.CreateAttribute($([PSObject]$Parameter.keys)[$($ParamNum - 1)])
                        $ParamAttr.value = $([PSObject]$Parameter.values)[$($ParamNum - 1)]
                        $ParameterElem.Attributes.Append($ParamAttr) > $null
                    }
                }
                $manifest.plasterManifest["parameters"].AppendChild($ParameterElem) > $Null
            }
        }

        if ($AddContentFromObject) {
            foreach ($content in $AddContentFromObject) {
                $contentElem = $manifest.CreateElement($($content['Type']), $TargetNamespace)
                ForEach ($ContentNum in $(1..$($content.count))) {
                    $ContentAttr = $manifest.CreateAttribute($([PSObject]$content.keys)[$($ContentNum - 1)])
                    $ContentAttr.value = $([PSObject]$content.values)[$($ContentNum - 1)]
                    $ContentElem.Attributes.Append($ContentAttr) > $null
                }
                $manifest.plasterManifest["content"].AppendChild($ContentElem) > $Null
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
