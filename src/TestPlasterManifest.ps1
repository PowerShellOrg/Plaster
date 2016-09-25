<#
.SYNOPSIS
    Verifies that a plaster manifest file is a valid.
.DESCRIPTION
    Verifies that a plaster manifest file is a valid.  The details of the
    errors can be viewed by using the Verbose parameter.
.EXAMPLE
    PS C:\> Test-PlasterManifest MyTemplate\plasterManifest.xml
    Verifies that the plasterManifest.xml file in the MyTemplate sub-directory
    is valid.
.EXAMPLE
    PS C:\> Test-PlasterManifest plasterManifest.xml -Verbose
    Verifies that the plasterManifest.xml file in the current directory
    is valid. If there are any validation errors, using -Verbose will
    display the details of those errors.
.INPUTS
    System.String
    You can pipe the path to a plaster manifest to Test-PlasterManifest.
.OUTPUTS
    System.Xml.XmlDocument

    Test-PlasterManifest returns a System.Xml.XmlDocument if the manifest is
    valid.  Otherwise it returns $null.
.LINK
    Invoke-Plaster
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
        $schemaPath = "$PSScriptRoot\Schema\PlasterManifest-v1.xsd"
        $xmlSchemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        $xmlSchemaSet.Add($targetNamespace, $schemaPath) > $null
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

        # Verify the manifest has the correct filename. Allow for localized template manifest files as well.
        if (!(($filename -eq 'plasterManifest.xml') -or ($filename -match 'plasterManifest_[a-zA-Z]+(-[a-zA-Z]+){0,2}.xml'))) {
            Write-Error ($LocalizedData.ManifestWrongFilename_F1 -f $filename)
            return
        }

        # Verify the manifest loads into an XmlDocument i.e. verify it is well-formed.
        $manifest = $null
        try {
            $manifest = [xml](Get-Content $Path)
        }
        catch {
            $ex = New-Object System.Exception ($LocalizedData.ManifestNotWellFormedXml_F2 -f $Path, $_.Exception.Message), $_.Exception
            $category = [System.Management.Automation.ErrorCategory]::InvalidData
            $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'InvalidManifestFile',$category,$Path
            $psCmdlet.WriteError($errRecord)
            return
        }

        # Validate the manifest contains the required root element and target namespace that the following
        # XML schema validation will apply to.
        if (!$manifest.plasterManifest) {
            Write-Error ($LocalizedData.ManifestMissingDocElement_F2 -f $Path,$targetNamespace)
            return
        }

        if ($manifest.plasterManifest.NamespaceURI -cne $targetNamespace) {
            Write-Error ($LocalizedData.ManifestMissingDocTargetNamespace_F2 -f $Path,$targetNamespace)
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
            Write-Error ($LocalizedData.ManifestErrorReading_F1 -f $_)
            $manifestIsValid.Value = $false
        }
        finally {
            $xmlReaderSettings.remove_ValidationEventHandler($validationEventHandler)
            if ($xmlReader) { $xmlReader.Dispose() }
        }

        # Validate that the requireModule attribute requiredVersion is mutually exclusive from both
        # the version and maximumVersion attributes.
        $requireModules= Select-Xml -Xml $manifest -XPath '//tns:requireModule' -Namespace @{tns = $targetNamespace}
        foreach ($requireModuleInfo in $requireModules) {
            $requireModuleNode = $requireModuleInfo.Node
            if ($requireModuleNode.requiredVersion -and ($requireModuleNode.minimumVersion -or $requireModuleNode.maximumVersion)) {
                $PSCmdLet.WriteVerbose($LocalizedData.ManifestSchemaInvalidRequireModuleAttrs_F1 -f $requireModuleNode.name)
                $manifestIsValid.Value = $false
            }
        }

        if ($manifestIsValid.Value) {
            $manifestSchemaVersion = [System.Version]$manifest.plasterManifest.schemaVersion

            # Use a simplified form (no patch version) of semver for checking XML schema version compatibility.
            if (($manifestSchemaVersion.Major -gt $LatestSupportedSchemaVersion.Major) -or
                (($manifestSchemaVersion.Major -eq $LatestSupportedSchemaVersion.Major) -and
                 ($manifestSchemaVersion.Minor -gt $LatestSupportedSchemaVersion.Minor))) {

                Write-Error ($LocalizedData.ManifestSchemaVersionNotSupported_F1 -f $manifestSchemaVersion)
                return
            }

            $manifest
        }
        else {
            Write-Error ($LocalizedData.ManifestNotValid_F1 -f $Path)
        }
    }
}
