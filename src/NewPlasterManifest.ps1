<#
.SYNOPSIS
    Creates a new Plaster template manifest file.
.DESCRIPTION
    The New-PlasterManifest command creates a new Plaster manifest file, populates its values, and saves the
    manifest file in the specified path.

    Template authors can use this command to create a manifest for their template. A template manifest is a file
    named plasterManifest.xml or plasterManifest_<culture-name>.xml. The information stored in the manifest is
    used to scaffold files and folders.

    The metadata section of the manifest is used to supply information about the template e.g. a unique id, name,
    version, title, author and tags.

    The parameters section of the manifest is used to describe choices the template user can choose from. Those
    choices are then used to conditionally create files and folders and modify existing files under the specified
    destination path.

    The content section is used to specify what actions the template will perform under the user's chosen
    destination directory.  This includes copying files to the destination, copy & expanding template files,
    modifying files, verifying required modules are installed and displaying messages to the user.

    See the help topic about_Plaster_CreatingAManifest for more details on authoring a Plaster manifest file.
.EXAMPLE
    PS C:\> New-PlasterManifest
    Creates a basic plasterManifest.xml file in the current directory.
.EXAMPLE
    PS C:\> New-PlasterManifest -TemplateVersion 0.1.0 -Description "Some description." -Tags Module, Publish,Build
    Creates a plasterManifest.xml file in the current directory with the version set to 0.1.0 and with the
    Description and Tags elements populated.
.EXAMPLE
    PS C:\> New-PlasterManifest -AddContent
    Creates a plasterManifest.xml file in the current directory with the content element filled in with all the
    files (except for any plasterManifest files) in and below the specified directory which defaults to the
    current directory.
.INPUTS
    None

    You cannot pipe input to this cmdlet.
.OUTPUTS
    None
.LINK
    Invoke-Plaster
    Test-PlasterManifest
#>
function New-PlasterManifest {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        # Specifies the path and file name of the new Plaster manifest. Enter a path and file name with a .xml
        # extension, such as $pshome\Modules\MyPlasterTemplate\plasterManifest.xml.  NOTE: Plaster requires the manifest
        # file be named either plasterManifest.xml OR plasterManifest_<culture-name>.xml e.g. plasterManifest_fr-FR.xml.
        # The default, if no value is provided is to create plasterManifest.xml in the current directory.
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$pwd\plasterManifest.xml",

        # Specifies the name of the template. A template name is required. For localized manifests, this value
        # should not be localized. The name is limited characters aA-zZ0-9_-.
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[0-9a-zA-Z_-]+$')]
        [string]
        $Name,

        # Unique identifier for all versions of this template. The id is a GUID. Use the same id for each version
        # of your template. This will prevent editor environments from listing multiple, installed versions of your
        # template. When you keep your template id the same, the editor will list only the latest version of your
        # template.
        [Parameter()]
        [Guid]
        $Id = [guid]::NewGuid(),

        # Specifies the version of the template.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d+\.\d+(\.\d+((\.\d+|(\+|-).*)?)?)?$')]
        [string]
        $TemplateVersion = "1.0.0",

        # Title of the Plaster template. This string is typically used in an editor like VSCode when displaying
        # a list of Plaster templates. A typical title might be "New DSC Resource" or "New PowerShell Module".
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Title = $Name,

        # Description of the Plaster template. This describes what the the template is for. It is typically used in
        # an editor like VSCode when displaying additional information about a Plaster template.
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
        $resolvedPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($Path)
        $manifestStr = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
    schemaVersion="$LatestSupportedSchemaVersion"
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
        $manifest.plasterManifest.metadata["name"].innerText = "$Name"
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
