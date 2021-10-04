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
        [string[]]
        $Path = @("$pwd\plasterManifest.xml")
    )

    begin {
        $schemaPath = [System.IO.Path]::Combine($PSScriptRoot, "Schema", "PlasterManifest-v1.xsd")

        # Schema validation is not available on .NET Core - at the moment.
        if ('System.Xml.Schema.XmlSchemaSet' -as [type]) {
            $xmlSchemaSet = New-Object System.Xml.Schema.XmlSchemaSet
            $xmlSchemaSet.Add($TargetNamespace, $schemaPath) > $null
        }
        else {
            $PSCmdLet.WriteWarning($LocalizedData.TestPlasterNoXmlSchemaValidationWarning)
        }
    }

    process {
        foreach ($aPath in $Path) {
            $aPath = $PSCmdLet.GetUnresolvedProviderPathFromPSPath($aPath)

            if (!(Test-Path -LiteralPath $aPath)) {
                $ex = New-Object System.Management.Automation.ItemNotFoundException ($LocalizedData.ErrorPathDoesNotExist_F1 -f $aPath)
                $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                $PSCmdLet.WriteError($errRecord)
                return
            }

            $filename = Split-Path $aPath -Leaf

            # Verify the manifest has the correct filename. Allow for localized template manifest files as well.
            if (!(($filename -eq 'plasterManifest.xml') -or ($filename -match 'plasterManifest_[a-zA-Z]+(-[a-zA-Z]+){0,2}.xml'))) {
                Write-Error ($LocalizedData.ManifestWrongFilename_F1 -f $filename)
                return
            }

            # Verify the manifest loads into an XmlDocument i.e. verify it is well-formed.
            $manifest = $null
            try {
                $manifest = [xml](Get-Content $aPath)
            }
            catch {
                $ex = New-Object System.Exception ($LocalizedData.ManifestNotWellFormedXml_F2 -f $aPath, $_.Exception.Message), $_.Exception
                $category = [System.Management.Automation.ErrorCategory]::InvalidData
                $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'InvalidManifestFile',$category,$aPath
                $psCmdlet.WriteError($errRecord)
                return
            }

            # Validate the manifest contains the required root element and target namespace that the following
            # XML schema validation will apply to.
            if (!$manifest.plasterManifest) {
                Write-Error ($LocalizedData.ManifestMissingDocElement_F2 -f $aPath,$TargetNamespace)
                return
            }

            if ($manifest.plasterManifest.NamespaceURI -cne $TargetNamespace) {
                Write-Error ($LocalizedData.ManifestMissingDocTargetNamespace_F2 -f $aPath,$TargetNamespace)
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
                        Write-Verbose ($LocalizedData.ManifestSchemaValidationError_F2 -f $aPath,$eventArgs.Message)
                        $manifestIsValid.Value = $false
                    }
                }

                $xmlReaderSettings.add_ValidationEventHandler($validationEventHandler)
            }

            [System.Xml.XmlReader]$xmlReader = $null
            try {
                $xmlReader = [System.Xml.XmlReader]::Create($aPath, $xmlReaderSettings)
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
                        $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidChoiceDefault_F3 -f $choiceParameter.default,$choiceParameter.name,$aPath))
                        $manifestIsValid.Value = $false
                    }
                }
                else {
                    if ($null -eq (($choiceParameter.default -split ',') -as [int[]])) {
                        $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidMultichoiceDefault_F3 -f $choiceParameter.default,$choiceParameter.name,$aPath))
                        $manifestIsValid.Value = $false
                    }
                }
            }

            # Validate that the requireModule attribute requiredVersion is mutually exclusive from both
            # the version and maximumVersion attributes.
            $requireModules = Select-Xml -Xml $manifest -XPath '//tns:requireModule' -Namespace @{tns = $TargetNamespace}
            foreach ($requireModuleInfo in $requireModules) {
                $requireModuleNode = $requireModuleInfo.Node
                if ($requireModuleNode.requiredVersion -and ($requireModuleNode.minimumVersion -or $requireModuleNode.maximumVersion)) {
                    $PSCmdLet.WriteVerbose(($LocalizedData.ManifestSchemaInvalidRequireModuleAttrs_F2 -f $requireModuleNode.name,$aPath))
                    $manifestIsValid.Value = $false
                }
            }

            # Validate that all the condition attribute values are valid PowerShell script.
            $conditionAttrs = Select-Xml -Xml $manifest -XPath '//@condition'
            foreach ($conditionAttr in $conditionAttrs) {
                $tokens = $errors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseInput($conditionAttr.Node.Value, [ref] $tokens, [ref] $errors)
                if ($errors.Count -gt 0) {
                    $msg = $LocalizedData.ManifestSchemaInvalidCondition_F3 -f $conditionAttr.Node.Value, $aPath, $errors[0]
                    $PSCmdLet.WriteVerbose($msg)
                    $manifestIsValid.Value = $false
                }
            }

            # Validate all interpolated attribute values are valid within a PowerShell string interpolation context.
            $interpolatedAttrs  = @(Select-Xml -Xml $manifest -XPath '//tns:parameter/@default' -Namespace @{tns = $TargetNamespace})
            $interpolatedAttrs += @(Select-Xml -Xml $manifest -XPath '//tns:parameter/@prompt' -Namespace @{tns = $TargetNamespace})
            $interpolatedAttrs += @(Select-Xml -Xml $manifest -XPath '//tns:content/tns:*/@*' -Namespace @{tns = $TargetNamespace})
            foreach ($interpolatedAttr in $interpolatedAttrs) {
                $name = $interpolatedAttr.Node.LocalName
                if ($name -eq 'condition') { continue }

                $tokens = $errors = $null
                $value = $interpolatedAttr.Node.Value
                $null = [System.Management.Automation.Language.Parser]::ParseInput("`"$value`"", [ref] $tokens, [ref] $errors)
                if ($errors.Count -gt 0) {
                    $ownerName = $interpolatedAttr.Node.OwnerElement.LocalName
                    $msg = $LocalizedData.ManifestSchemaInvalidAttrValue_F5 -f $name, $value, $ownerName, $aPath, $errors[0]
                    $PSCmdLet.WriteVerbose($msg)
                    $manifestIsValid.Value = $false
                }
            }

            if ($manifestIsValid.Value) {
                # Verify manifest schema version is supported.
                $manifestSchemaVersion = [System.Version]$manifest.plasterManifest.schemaVersion

                # Use a simplified form (no patch version) of semver for checking XML schema version compatibility.
                if (($manifestSchemaVersion.Major -gt $LatestSupportedSchemaVersion.Major) -or
                    (($manifestSchemaVersion.Major -eq $LatestSupportedSchemaVersion.Major) -and
                     ($manifestSchemaVersion.Minor -gt $LatestSupportedSchemaVersion.Minor))) {

                    Write-Error ($LocalizedData.ManifestSchemaVersionNotSupported_F2 -f $manifestSchemaVersion,$aPath)
                    return
                }

                # Verify that the plasterVersion is supported.
                if ($manifest.plasterManifest.plasterVersion) {
                    $requiredPlasterVersion = [System.Version]$manifest.plasterManifest.plasterVersion

                    # Is user specifies major.minor, change build to 0 (from default of -1) so compare works correctly.
                    if ($requiredPlasterVersion.Build -eq -1) {
                        $requiredPlasterVersion = [System.Version]"${requiredPlasterVersion}.0"
                    }

                    if ($requiredPlasterVersion -gt $MyInvocation.MyCommand.Module.Version) {
                        $plasterVersion = $manifest.plasterManifest.plasterVersion
                        Write-Error ($LocalizedData.ManifestPlasterVersionNotSupported_F2 -f $aPath,$plasterVersion)
                        return
                    }
                }

                $manifest
            }
            else {
                if ($PSBoundParameters['Verbose']) {
                    Write-Error ($LocalizedData.ManifestNotValid_F1 -f $aPath)
                }
                else {
                    Write-Error ($LocalizedData.ManifestNotValidVerbose_F1 -f $aPath)
                }
            }
        }
    }
}
