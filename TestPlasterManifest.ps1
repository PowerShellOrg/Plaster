<#
.SYNOPSIS
    Verifies that a plaster manifest file is a valid.
.DESCRIPTION
    Verifies that a plaster manifest file is a valid.
.EXAMPLE
    C:\PS> Test-PlasterManifest plasterManifest.xml
    Verifies that the plasterManifest.xml file in the current directory
    is valid.
.INPUTS
    System.String
    You can pipe the path to a plaster manifest to Test-PlasterManifest.
.OUTPUTS
    System.Boolean
    Returns "True" when the plaster manifest file is valid and "False" when
    it isn't valid.
.NOTES
    General notes
#>
function Test-PlasterManifest {
    [CmdletBinding()]
    param(
        # Specifies a path to a plasterManifest.xml file.
        [Parameter(Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Specifies a path to a plasterManifest.xml file.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path = "$pwd\plasterManifest.xml"
    )

    begin {
        $targetNamespace = "http://www.microsoft.com/schemas/PowerShell/Plaster/v1"
        $schemaPath = "$PSScriptRoot\Schema\PlasterManifest-v1.xsd"
        $xmlSchemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        $null = $xmlSchemaSet.Add($targetNamespace, $schemaPath)
    }

    process {
        $Path = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($Path)

        if (!(Test-Path -LiteralPath $Path)) {
            $ex = New-Object System.Management.Automation.ItemNotFoundException ($LocalizedData.ErrorPathDoesNotExist_F1 -f $Path)
            $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
            $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$Path
            $psCmdlet.WriteError($errRecord)
            return
        }

        $filename = Split-Path $Path -Leaf

        if ($filename -ne 'plasterManifest.xml') {
            Write-Error ($LocalizedData.ManifestWrongFilename_F1 -f $filename)
            return
        }

        $manifest = $null
        try {
            $manifest = [xml](Get-Content $Path)
        }
        catch {
            Write-Error ($LocalizedData.ManifestNotValidXml_F1 -f $Path)
            return
        }

        # Validate the required elements of the manifest are present
        if (!$manifest.plasterManifest) {
            Write-Error ($LocalizedData.ManifestMissingDocElement_F2 -f $Path,$targetNamespace)
            return
        }

        # Valid flag is stashed in a hashtable so the ValidationEventHandler scriptblock can set the value.
        $manifestIsValid = @{Value = $true}

        # Configure an XmlReader and XmlReaderSettings to perform schema validation on xml file.
        $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
        $xmlReaderSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
        $xmlReaderSettings.ValidationType = [System.Xml.ValidationType]::Schema
        $xmlReaderSettings.Schemas = $xmlSchemaSet

        # Event handler scriptblock for the ValidationEventHandler event.
        $validationEventHandler = {
            param($sender, $eventArgs)

            if ($eventArgs.Severity -eq [System.Xml.Schema.XmlSeverityType]::Error)
            {
                Write-Verbose ($LocalizedData.ManifestSchemaValidationError_F1 -f $eventArgs.Message)
                $manifestIsValid.Value = $false
            }
        }

        $xmlReaderSettings.add_ValidationEventHandler($validationEventHandler)

        [System.Xml.XmlReader]$xmlReader = $null
        try {
            $xmlReader = [System.Xml.XmlReader]::Create($Path, $xmlReaderSettings)
            while ($xmlReader.Read()) {}
        }
        catch {
            Write-Error ($LocalizedData.ManifestErrorReading_F1 -f $_.Message)
            $manifestIsValid.Value = $false
        }
        finally {
            $xmlReaderSettings.remove_ValidationEventHandler($validationEventHandler)
            if ($xmlReader) { $xmlReader.Dispose() }
        }

        if ($manifestIsValid.Value) {
            $manifest
        }
        else {
            Write-Error ($LocalizedData.ManifestNotValid_F1 -f $Path)
        }
    }
}
