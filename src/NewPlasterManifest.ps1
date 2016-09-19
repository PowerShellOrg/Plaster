<#
.SYNOPSIS
    Creates a Plaster template manifest.
.DESCRIPTION
    The New-PlasterManifest command creates a new Plaster manifest file, populates its values, and saves the
    manifest file in the specified path.

    Template authors can use this command to create a manifest for their template. A template manifest is a file
    named plasterManifest.xml or plasterManifest_<culture-name>.xml.  The information stored in the manifest is
    used to scaffold files and folders.

    The parameters section of the manifest is used to describe choices the template user can choose from. Those
    choices are then used to conditionally create files and folders and modify existing files under the specified
    destination path.
.EXAMPLE
    PS C:\> New-PlasterManifest
    Creates a basic plasterManifest.xml file in the current directory.
.EXAMPLE
    PS C:\> New-PlasterManifest -TemplateVersion 0.1.0 -Description "Some description." -Tags Module, Publish, Build
    Creates a plasterManifest.xml file in the current directory with the version set to 0.1.0 and with the
    Description and Tags elements populated.
.EXAMPLE
    PS C:\> New-PlasterManifest -AddContent
    Creates a plasterManifest.xml file in the current directory with the content element filled in with all the files
    in and below the current directory (except for any plasterManifest files).
.INPUTS
    None

    You cannot pipe input to this cmdlet.
.OUTPUTS
    None
.LINK
    Invoke-Plaster
#>
function New-PlasterManifest {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        # Specifies the path and file name of the new Plaster manifest. Enter a path and file name with a .xml file name
        # extension, such as $pshome\Modules\MyPlasterTemplate\plasterManifest.xml.  NOTE: Plaster requires the manifest
        # file be named either plasterManifest.xml OR plasterManifest_<culture-name>.xml e.g. plasterManifest_fr-FR.xml.
        # The default, if no value is provided is to create plasterManifest.xml in the current directory.
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$pwd\plasterManifest.xml",

        # Unique identifier for all versions of this template.  The id is a GUID.  Use the same id for each version
        # of your template.  This will prevent editor environments from listing multiple, installed versions of your
        # template. When the id stays the same, the editor will list only the latest version of your template.
        [Parameter()]
        [Guid]
        $Id = [guid]::NewGuid(),

        # Specifies the version of the template.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d+\.\d+(\.\d+((\.\d+|(\+|-).*)?)?)?$')]
        [string]
        $TemplateVersion = "1.0.0",

        # Title of the Plaster template.  This short string is typically used in an editor like VSCode when displaying
        # a list of Plaster templates.  A typical title might be "New DSC Resource" or "New PowerShell Module".
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Title,

        # Description of the Plaster template.  This is a longer descrition of what the the template is for. It
        # is typically used in an editor like VSCode when displaying additional information about a Plaster template.
        # A typical title might be "Creates files required for a PowerShell module with optional support for Pester
        # tests, building with psake and publishing to the PowerShell Gallery."
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        # Specifies an array of tags for the template.  Users can search for templates based on these tags.
        [Parameter()]
        [string[]]
        $Tags,

        # Specifies the author of the template.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Author,

        # If specified, the contents of the directory the manifest is being created in will be added to the
        # manifest's content element.
        [Parameter()]
        [switch]
        $AddContent
    )

    begin {
        $manifestStr = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
    schemaVersion="$LatestSupportedSchemaVersion"
    xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">

    <metadata>
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

        # This configures the XmlWriter to put attributes on a new line
        $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
        $xmlWriterSettings.Indent = $true
        $xmlWriterSettings.NewLineOnAttributes = $true

        try {
            if ($PSCmdlet.ShouldProcess($Path, $LocalizedData.ShouldCreateNewPlasterManifest)) {
                $xmlWriter = [System.Xml.XmlWriter]::Create($Path, $xmlWriterSettings)
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
