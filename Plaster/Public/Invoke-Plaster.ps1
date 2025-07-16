## TODO: Create tests to ensure check for these.
## DEVELOPERS NOTES & CONVENTIONS
##
##  1. All text displayed to the user except for Write-Debug (or $PSCmdlet.WriteDebug()) text must be added to the
##     string tables in:
##         en-US\Plaster.psd1
##         Plaster.psm1
##  2. If a new manifest element is added, it must be added to the Schema\PlasterManifest-v1.xsd file and then
##     processed in the appropriate function in this script.  Any changes to <parameter> attributes must be
##     processed not only in the Resolve-ProcessParameter function but also in the dynamicparam function.
##
##  3. Non-exported functions should avoid using the PowerShell standard Verb-Noun naming convention.
##     They should use PascalCase instead.
##
##  4. Please follow the scripting style of this file when adding new script.

function Invoke-Plaster {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath,

        [Parameter(Position = 1, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $NoLogo,

        [Parameter()]
        [switch]
        $PassThru
    )

    # Process the template's Plaster manifest file to convert parameters defined there into dynamic parameters.
    dynamicparam {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $manifest = $null
        $manifestPath = $null
        $templateAbsolutePath = $null

        # Nothing to do until the TemplatePath parameter has been provided.
        if ($null -eq $TemplatePath) {
            return
        }

        try {
            # Let's convert non-terminating errors in this function to terminating so we
            # catch and format the error message as a warning.
            $ErrorActionPreference = 'Stop'

            # The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
            # since we are only evaluating the parameters in the manifest - no need for Test-ConditionAttribute as we
            # are not building up multiple parametersets.  And no need for EvaluateAttributeValue since we are only
            # grabbing the parameter's value which is static.
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)
            if (!(Test-Path -LiteralPath $templateAbsolutePath -PathType Container)) {
                throw ($LocalizedData.ErrorTemplatePathIsInvalid_F1 -f $templateAbsolutePath)
            }

            # Load manifest file using culture lookup
            $manifestPath = Get-PlasterManifestPathForCulture $templateAbsolutePath $PSCulture
            if (($null -eq $manifestPath) -or (!(Test-Path $manifestPath))) {
                return
            }

            $manifest = Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            # The user-defined parameters in the Plaster manifest are converted to dynamic parameters
            # which allows the user to provide the parameters via the command line.
            # This enables non-interactive use cases.
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) {
                    continue
                }

                $name = $node.name
                $type = $node.type
                $prompt = if ($node.prompt) { $node.prompt } else { $LocalizedData.MissingParameterPrompt_F1 -f $name }

                if (!$name -or !$type) { continue }

                # Configure ParameterAttribute and add to attr collection
                $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type) {
                    'text|user-fullname|user-email' {
                        $param = New-Object System.Management.Automation.RuntimeDefinedParameter `
                            -ArgumentList ($name, [string], $attributeCollection)
                        break
                    }

                    'choice|multichoice' {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object string[] $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes) {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object System.Management.Automation.ValidateSetAttribute $setValues
                        $attributeCollection.Add($validateSetAttr)
                        $type = if ($type -eq 'multichoice') { [string[]] } else { [string] }
                        $param = New-Object System.Management.Automation.RuntimeDefinedParameter `
                            -ArgumentList ($name, $type, $attributeCollection)
                        break
                    }

                    default { throw ($LocalizedData.UnrecognizedParameterType_F2 -f $type, $name) }
                }

                $paramDictionary.Add($name, $param)
            }
        } catch {
            Write-Warning ($LocalizedData.ErrorProcessingDynamicParams_F1 -f $_)
        }

        $paramDictionary
    }

    begin {
        # Write out the Plaster logo if necessary
        $plasterLogo = @'
  ____  _           _
 |  _ \| | __ _ ___| |_ ___ _ __
 | |_) | |/ _` / __| __/ _ \ '__|
 |  __/| | (_| \__ \ ||  __/ |
 |_|   |_|\__,_|___/\__\___|_|
'@

        if (!$NoLogo) {
            $versionString = "v$PlasterVersion"
            Write-Host $plasterLogo
            Write-Host ((" " * (50 - $versionString.Length)) + $versionString)
            Write-Host ("=" * 50)
        }

        #region Script Scope Variables
        # These are used across different private functions.
        $script:boundParameters = $PSBoundParameters
        $script:constrainedRunspace = $null
        $script:templateCreatedFiles = @{}
        $script:defaultValueStore = @{}
        $script:fileConflictConfirmNoToAll = $false
        $script:fileConflictConfirmYesToAll = $false
        $script:flags = @{
            DefaultValueStoreDirty = $false
        }
        #endregion Script Scope Variables

        # Verify TemplatePath parameter value is valid.
        $templateAbsolutePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($TemplatePath)
        if (!(Test-Path -LiteralPath $templateAbsolutePath -PathType Container)) {
            throw ($LocalizedData.ErrorTemplatePathIsInvalid_F1 -f $templateAbsolutePath)
        }

        # We will have a null manifest if the dynamicparam scriptblock was unable to load the template manifest
        # or it wasn't valid. If so, let's try to load it here. If anything, we can provide better errors here.
        if ($null -eq $manifest) {
            if ($null -eq $manifestPath) {
                $manifestPath = Get-PlasterManifestPathForCulture $templateAbsolutePath $PSCulture
            }

            if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                $manifest = Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null
                $PSCmdlet.WriteDebug("In begin, loading manifest file '$manifestPath'")
            } else {
                throw ($LocalizedData.ManifestFileMissing_F1 -f $manifestPath)
            }
        }

        # If the destination path doesn't exist, create it.
        $destinationAbsolutePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        if (!(Test-Path -LiteralPath $destinationAbsolutePath)) {
            New-Item $destinationAbsolutePath -ItemType Directory > $null
        }

        # Prepare output object if user has specified the -PassThru parameter.
        if ($PassThru) {
            $InvokePlasterInfo = [PSCustomObject]@{
                TemplatePath = $templateAbsolutePath
                DestinationPath = $destinationAbsolutePath
                Success = $false
                TemplateType = if ($manifest.plasterManifest.templateType) { $manifest.plasterManifest.templateType } else { 'Unspecified' }
                CreatedFiles = [string[]]@()
                UpdatedFiles = [string[]]@()
                MissingModules = [string[]]@()
                OpenFiles = [string[]]@()
            }
        }

        # Create the pre-defined Plaster variables.
        Initialize-PredefinedVariables -TemplatePath $templateAbsolutePath -DestPath $destinationAbsolutePath

        # Check for any existing default value store file and load default values if file exists.
        $templateId = $manifest.plasterManifest.metadata.id
        $templateVersion = $manifest.plasterManifest.metadata.version
        $templateName = $manifest.plasterManifest.metadata.name
        $storeFilename = "$templateName-$templateVersion-$templateId.clixml"
        $script:defaultValueStorePath = Join-Path $ParameterDefaultValueStoreRootPath $storeFilename
        if (Test-Path $script:defaultValueStorePath) {
            try {
                $PSCmdlet.WriteDebug("Loading default value store from '$script:defaultValueStorePath'.")
                $script:defaultValueStore = Import-Clixml $script:defaultValueStorePath -ErrorAction Stop
            } catch {
                Write-Warning ($LocalizedData.ErrorFailedToLoadStoreFile_F1 -f $script:defaultValueStorePath)
            }
        }
    }

    end {
        try {
            # Process parameters
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) { continue }
                switch ($node.LocalName) {
                    'parameter' { Resolve-ProcessParameter $node }
                    default { throw ($LocalizedData.UnrecognizedParametersElement_F1 -f $node.LocalName) }
                }
            }

            # Outputs the processed template parameters to the debug stream
            $parameters = Get-Variable -Name PLASTER_* | Out-String
            $PSCmdlet.WriteDebug("Parameter values are:`n$($parameters -split "`n")")

            # Stores any updated default values back to the store file.
            if ($script:flags.DefaultValueStoreDirty) {
                $directory = Split-Path $script:defaultValueStorePath -Parent
                if (!(Test-Path $directory)) {
                    $PSCmdlet.WriteDebug("Creating directory for template's DefaultValueStore '$directory'.")
                    New-Item $directory -ItemType Directory > $null
                }

                $PSCmdlet.WriteDebug("DefaultValueStore is dirty, saving updated values to '$script:defaultValueStorePath'.")
                $script:defaultValueStore | Export-Clixml -LiteralPath $script:defaultValueStorePath
            }

            # Output the DestinationPath
            Write-Host ($LocalizedData.DestPath_F1 -f $destinationAbsolutePath)

            # Process content
            foreach ($node in $manifest.plasterManifest.content.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) { continue }

                switch -Regex ($node.LocalName) {
                    'file|templateFile' { Start-ProcessFile $node; break }
                    'message' { Resolve-ProcessMessage $node; break }
                    'modify' { Start-ProcessModifyFile $node; break }
                    'newModuleManifest' { Resolve-ProcessNewModuleManifest $node; break }
                    'requireModule' { Start-ProcessFileProcessRequireModule $node; break }
                    default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
                }
            }

            if ($PassThru) {
                $InvokePlasterInfo.Success = $true
                $InvokePlasterInfo
            }
        } finally {
            # Dispose of the ConstrainedRunspace.
            if ($script:constrainedRunspace) {
                $script:constrainedRunspace.Dispose()
                $script:constrainedRunspace = $null
            }
        }
    }
}
