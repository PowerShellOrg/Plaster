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
    [CmdletBinding(DefaultParameterSetName = 'TemplatePath', SupportsShouldProcess = $true, DefaultParameterSetName = 'TemplatePath')]
    param(
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'TemplatePath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'TemplateDefinition')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateDefinition,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'TemplateDefinition')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplateDefinition,

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

        # Enhanced dynamic parameter processing for both XML and JSON
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
            $templateAbsolutePath = $ExecutionConteut            # Load manifest file using culture lookup
            # Determine manifest type and process accordingly
            try {
                $manifestType = Get-PlasterManifestType -ManifestPath $manifestPath
                Write-Debug "Detected manifest type: $manifestType for path: $manifestPath"
            } catch {
                Write-Warning "Failed to determine manifest type for '$manifestPath': $($_.Exception.Message)"
                return
            }

            #
            Process JSON manifests
            if ($manifestType -eq 'JSON') {
                try {
                    $jsonContent = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop
                    $manifest = ConvertFrom-JsonManifest -JsonContent $jsonContent -ErrorAction Stop
                    Write-Debug "Successfully converted JSON manifest to XML for processing"
                } catch {
                    Write-Warning "Failed to process JSON manifest '$manifestPath': $($_.Exception.Message)"
                    return
                }
            } else {
                #
                Process XML manifests (existing logic)
                $manifest = Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null
            }ture
            if (($null -eq $manifestPath) -or (!(Test-Path $manifestPath))) {

                return
            }

            $

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
        # Enhanced logo with JSON support indicator
        $plasterLogo = @'
  ____  _           _              ____   ___
 |  _ \| | __ _ ___| |_ ___ _ __   |___ \ / _ \
 | |_) | |/ _` / __| __/ _ \ '__|    __) | | | |
 |  __/| | (_| \__ \ ||  __/ |      / /| |_| | /
 |_|   |_|\__,_|___/\__\___|_|     |____|\___/
'@

        if (!$NoLogo) {
            $versionString = "v$PlasterVersion (JSON Enhanced)"
            Write-Host $plasterLogo -ForegroundColor Blue
            Write-Host ((" " * (50 - $versionString.Length)) + $versionString) -ForegroundColor Cyan
            Write-Host ("=" * 50) -ForegroundColor Blue
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

        # Determine template source and type
        if ($PSCmdlet.ParameterSetName -eq 'TemplatePath') {
            $templateAbsolutePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($TemplatePath)
            if (!(Test-Path -LiteralPath $templateAbsolutePath -PathType Container)) {
                throw ($LocalizedData.ErrorTemplatePathIsInvalid_F1 -f $templateAbsolutePath)
            }

            # Determine manifest type and path
            $jsonManifestPath = Join-Path $templateAbsolutePath 'plasterManifest.json'
            $xmlManifestPath = GetPlasterManifestPathForCulture $templateAbsolutePath $PSCulture

            if (Test-Path -LiteralPath $jsonManifestPath) {
                $manifestPath = $jsonManifestPath
                $manifestType = 'JSON'
                Write-PlasterLog -Level Information -Message "Using JSON manifest: $($manifestPath | Split-Path -Leaf)"
            } elseif (($null -ne $xmlManifestPath) -and (Test-Path $xmlManifestPath)) {
                $manifestPath = $xmlManifestPath
                $manifestType = 'XML'
                Write-PlasterLog -Level Information -Message "Using XML manifest: $($manifestPath | Split-Path -Leaf)"
            } else {
                throw ($LocalizedData.ManifestFileMissing_F1 -f "plasterManifest.json or plasterManifest.xml")
            }

        } else {
            # TemplateDefinition parameter set
            $manifestType = if ($TemplateDefinition.TrimStart() -match '^[\s]*[\{\[]') { 'JSON' } else { 'XML' }
            $templateAbsolutePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
            Write-PlasterLog -Level Information -Message "Using inline $manifestType template definition"
        }

        # Process manifest based on type

        if ($null -eq $manifest) {
            if ($manifestType -eq 'JSON') {
                $manifestContent = if ($manifestPath) {
                    Get-Content -LiteralPath $manifestPath -Raw
                } else {
                    $TemplateDefinition
                }

                # Validate and convert JSON manifest
                $isValid = Test-JsonManifest -JsonContent $manifestContent -Detailed
                if (-not $isValid) {
                    throw "JSON manifest validation failed"
                }

                $manifest = ConvertFrom-JsonManifest -JsonContent $manifestContent
                Write-PlasterLog -Level Debug -Message "JSON manifest converted to internal format"

            } else {
                # Load XML manifest

                if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                    $manifest = Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null
                    $PSCmdlet.WriteDebug("Loading XML manifest file '$manifestPath'")
                } else {
                    throw ($LocalizedData.ManifestFileMissing_F1 -f $manifestPath)
                }
            }
        }

        # Validate destination path
        $destinationAbsolutePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        if (!(Test-Path -LiteralPath $destinationAbsolutePath)) {
            New-Item $destinationAbsolutePath -ItemType Directory > $null
            Write-PlasterLog -Level Information -Message "Created destination directory: $destinationAbsolutePath"
        }

        # Prepare output object if user has specified the -PassThru parameter.
        if ($PassThru) {
            $InvokePlasterInfo = [PSCustomObject]@{
                TemplatePath = if ($templateAbsolutePath) { $templateAbsolutePath } else { 'Inline Definition' }
                DestinationPath = $destinationAbsolutePath
                ManifestType = $manifestType
                Success = $false
                TemplateType = if ($manifest.plasterManifest.templateType) { $manifest.plasterManifest.templateType } else { 'Unspecified' }
                CreatedFiles = [string[]]@()
                UpdatedFiles = [string[]]@()
                MissingModules = [string[]]@()
                OpenFiles = [string[]]@()
                ProcessingTime = $null
            }
        }

        # Initialize pre-defined variables
        if ($templateAbsolutePath) {
            Initialize-PredefinedVariables -TemplatePath $templateAbsolutePath -DestPath $destinationAbsolutePath
        } else {
            Initialize-PredefinedVariables -TemplatePath $destinationAbsolutePath -DestPath $destinationAbsolutePath
        }

        # Enhanced default value store handling
        $templateId = $manifest.plasterManifest.metadata.id
        $templateVersion = $manifest.plasterManifest.metadata.version
        $templateName = $manifest.plasterManifest.metadata.name
        $storeFilename = "$templateName-$templateVersion-$templateId.clixml"
        $script:defaultValueStorePath = Join-Path $ParameterDefaultValueStoreRootPath $storeFilename
        if (Test-Path $script:defaultValueStorePath) {
            try {
                $PSCmdlet.WriteDebug("Loading default value store from '$script:defaultValueStorePath'.")
                $script:defaultValueStore = Import-Clixml $script:defaultValueStorePath -ErrorAction Stop
                Write-PlasterLog -Level Debug -Message "Loaded parameter defaults from store"
            } catch {
                Write-Warning ($LocalizedData.ErrorFailedToLoadStoreFile_F1 -f $script:defaultValueStorePath)
            }
        }
    }

    end {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            Write-PlasterLog -Level Information -Message "Starting template processing ($manifestType format)"

            # Process parameters with enhanced JSON support
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) { continue }
                switch ($node.LocalName) {
                    'parameter' { Resolve-ProcessParameter $node }
                    default { throw ($LocalizedData.UnrecognizedParametersElement_F1 -f $node.LocalName) }
                }
            }

            # Output processed parameters for debugging
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

            # Output destination path
            Write-Host ($LocalizedData.DestPath_F1 -f $destinationAbsolutePath)

            # Process content with enhanced logging
            foreach ($node in $manifest.plasterManifest.content.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) { continue }

                Write-PlasterLog -Level Debug -Message "Processing content action: $($node.LocalName)"
                switch -Regex ($node.LocalName) {
                    'file|templateFile' { Start-ProcessFile $node; break }
                    'message' { Resolve-ProcessMessage $node; break }
                    'modify' { Start-ProcessModifyFile $node; break }
                    'newModuleManifest' { Resolve-ProcessNewModuleManifest $node; break }
                    'requireModule' { Start-ProcessFileProcessRequireModule $node; break }
                    default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
                }
            }
            $stopwatch.Stop()

            if ($PassThru) {
                $InvokePlasterInfo.Success = $true
                $InvokePlasterInfo.ProcessingTime = $stopwatch.Elapsed
                Write-PlasterLog -Level Information -Message "Template processing completed successfully in $($stopwatch.Elapsed.TotalSeconds) seconds"
                return $InvokePlasterInfo
            } else {
                Write-PlasterLog -Level Information -Message "Template processing completed successfully in $($stopwatch.Elapsed.TotalSeconds) seconds"
            }
        }
        catch {
            $stopwatch.Stop()
            $errorMessage = "Template processing failed after $($stopwatch.Elapsed.TotalSeconds) seconds: $($_.Exception.Message)"
            Write-PlasterLog -Level Error -Message $errorMessage

            if ($PassThru) {
                $InvokePlasterInfo.Success = $false
                $InvokePlasterInfo.ProcessingTime = $stopwatch.Elapsed
                return $InvokePlasterInfo
            }

            throw $_
        }
        finally {
            # Enhanced cleanup
            if ($script:constrainedRunspace) {
                $script:constrainedRunspace.Dispose()
                $script:constrainedRunspace = $null
                Write-PlasterLog -Level Debug -Message "Disposed constrained runspace"
            }
        }
    }
}
