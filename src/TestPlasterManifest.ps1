function Test-PlasterManifest {
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param(
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

        # Schema validation is not available on .NET Core - at the moment.
        if ('System.Xml.Schema.XmlSchemaSet' -as [type]) {
            $xmlSchemaSet = New-Object System.Xml.Schema.XmlSchemaSet
            $xmlSchemaSet.Add($targetNamespace, $schemaPath) > $null
        }
        else {
            $PSCmdLet.WriteWarning($LocalizedData.TestPlasterNoXmlSchemaValidationWarning)
        }
    }

    process {
        $Path = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($Path)

        if (!(Test-Path -LiteralPath $Path)) {
            $ex = New-Object System.Management.Automation.ItemNotFoundException ($LocalizedData.ErrorPathDoesNotExist_F1 -f $Path)
            $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
            $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$Path
            $PSCmdLet.WriteError($errRecord)
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

        # Schema validation is not available on .NET Core - at the moment.
        if ($xmlSchemaSet) {
            $xmlReaderSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
            $xmlReaderSettings.ValidationType = [System.Xml.ValidationType]::Schema
            $xmlReaderSettings.Schemas = $xmlSchemaSet
        }

        # Schema validation is not available on .NET Core - at the moment.
        if ($xmlSchemaSet) {
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
        }

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
            # Schema validation is not available on .NET Core - at the moment.
            if ($xmlSchemaSet) {
                $xmlReaderSettings.remove_ValidationEventHandler($validationEventHandler)
            }
            if ($xmlReader) { $xmlReader.Dispose() }
        }

        # Validate default values for choice/multichoice parameters containing 1 or more ints
        $xpath = "//tns:parameter[@type='choice'] | //tns:parameter[@type='multichoice']"
        $choiceParameters = Select-Xml -Xml $manifest -XPath $xpath  -Namespace @{tns=$TargetNamespace}
        foreach ($choiceParameterXmlInfo in $choiceParameters) {
            $choiceParameter = $choiceParameterXmlInfo.Node
            if (!$choiceParameter.default) { continue }

            if ($choiceParameter.type -eq 'choice') {
                if ($null -eq ($choiceParameter.default -as [int])) {
                    $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidChoiceDefault_F2 -f $choiceParameter.default,$choiceParameter.name))
                    $manifestIsValid.Value = $false
                }
            }
            else {
                if ($null -eq (($choiceParameter.default -split ',') -as [int[]])) {
                    $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidMultichoiceDefault_F2 -f $choiceParameter.default,$choiceParameter.name))
                    $manifestIsValid.Value = $false
                }
            }
        }

        # Validate that the requireModule attribute requiredVersion is mutually exclusive from both
        # the version and maximumVersion attributes.
        $requireModules = Select-Xml -Xml $manifest -XPath '//tns:requireModule' -Namespace @{tns = $targetNamespace}
        foreach ($requireModuleInfo in $requireModules) {
            $requireModuleNode = $requireModuleInfo.Node
            if ($requireModuleNode.requiredVersion -and ($requireModuleNode.minimumVersion -or $requireModuleNode.maximumVersion)) {
                $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidRequireModuleAttrs_F1 -f $requireModuleNode.name))
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
            if ($PSBoundParameters['Verbose']) {
                Write-Error ($LocalizedData.ManifestNotValid_F1 -f $Path)
            }
            else {
                Write-Error ($LocalizedData.ManifestNotValidVerbose_F1 -f $Path)
            }
        }
    }
}
