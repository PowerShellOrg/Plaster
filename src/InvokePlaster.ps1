<#
NOTE TO DEVELOPERS:
All text displayed to the user except for Write-Debug (or $PSCmdlet.WriteDebug()) text must be added to the
string tables in:
    en-US\Plaster.psd1
    Plaster.psm1

If a new manifest element is added, it must be added to the Schema\PlasterManifest-v1.xsd file and then
processed in the appropriate function in this script.  Any changes to <parameter> attributes must be
processed not only in the ProcessParameter function but also in the dynamicparam function.

Please follow the scripting style of this file when adding new script.
#>

<#
.SYNOPSIS
    Invokes the specified plaster template which will scaffold out a file or set of files.
.DESCRIPTION
    Invokes the specified plaster template which will scaffold out a file or set of files.
.EXAMPLE
    C:\PS> Invoke-Plaster -TemplatePath NewModule.zip -Destination .\NewModule
    Explanation of what the example does
.NOTES
    General notes
#>
function Invoke-Plaster {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='CopyFileWithConflictDetection')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='GenerateModuleManifest')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ModifyFile')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ProcessFile')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidShouldContinueWithoutForce', '', Scope='Function', Target='ProcessFile')]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        # Specifies the path to either the Template directory or a ZIP file containing the template.
        # If no directory is specified the current directory is used.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath = $pwd.Path,

        # Specifies the path to directory in which the template will use as a root directory when generating files.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        # Specify Force to override user prompts for conflicting handling.  This will override the confirmation
        # prompt and allow the template to over write existing files.
        [Parameter()]
        [switch]
        $Force,

        # Suppresses the display of the Plaster logo.
        [Parameter()]
        [switch]
        $NoLogo
    )

    # Process the template's plaster manifest file to convert parameters defined there into dynamic parameters.
    dynamicparam {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $manifest = $null
        $manifestPath = $null

        if ($null -eq $TemplatePath) {
            $TemplatePath = $pwd.Path
        }

        try {
            # If TemplatePath is a zipped template, extract the template to a temp dir and use that path
            $TemplatePath = ExtractTemplateAndReturnPath $TemplatePath

            $manifestPath = Join-Path $TemplatePath plasterManifest.xml
            if ($null -eq $manifestPath) {
                return
            }

            # Can't seem to use $PSCmdlet.GetUnresolvedProviderPathFromPSPath in dynamicparam scriptblock.
            $manifestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($manifestPath)
            if (!(Test-Path $manifestPath)) {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop

            # The user-defined parameters in the Plaster manifest are converted to dynamic parameters
            # which allows the user to provide the parameters via the command line.
            # This enables non-interactive use cases.
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) {
                    continue
                }

                $name = $node.name
                $type = $node.type
                $prompt = $node.prompt

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

                        foreach ($choiceNode in $choiceNodes){
                            $setValues[$i++] = ExpandString $choiceNode.value
                        }

                        $validateSetAttr = New-Object System.Management.Automation.ValidateSetAttribute $setValues
                        $attributeCollection.Add($validateSetAttr)
                        $type = if ($type -eq 'multichoice') { [string[]] } else { [string] }
                        $param = New-Object System.Management.Automation.RuntimeDefinedParameter `
                                     -ArgumentList ($name, $type, $attributeCollection)
                        break
                    }

                    default { throw ($LocalizedData.UnrecognizedParameterType_F2 -f $type,$name) }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch [System.Exception] {
            Write-Verbose ($LocalizedData.ErrorProcessingDynamicParams_F1 -f $_)
        }

        $paramDictionary
    }

    begin {
        $boundParameters = $PSBoundParameters
        $templateCreatedFiles = @{}
        $defaultValueStore = @{}
        $fileConflictConfirmNoToAll = $false
        $fileConflictConfirmYesToAll = $false
        $flags = @{
            DefaultValueStoreDirty = $false
        }

        $logo = @'
__________.__                   __
\______   \  | _____    _______/  |_  ___________
 |     ___/  | \__  \  /  ___/\   __\/ __ \_  __ \
 |    |   |  |__/ __ \_\___ \  |  | \  ___/|  | \/
 |____|   |____(____  /____  > |__|  \___  >__|
                    \/     \/            \/
'@, @'
  ____  _           _
 |  _ \| | __ _ ___| |_ ___ _ __
 | |_) | |/ _` / __| __/ _ \ '__|
 |  __/| | (_| \__ \ ||  __/ |
 |_|   |_|\__,_|___/\__\___|_|
'@, @'
    _____
   (, /   ) /)
    _/__ / // _   _  _/_  _  __
    /     (/_(_(_/_)_(___(/_/ (_
 ) /
(_/
'@

        if (!$NoLogo) {
            $randLogo = $logo[(Get-Random -Minimum 0 -Maximum $logo.Length)]
            Write-Host $randLogo
            Write-Host ("=" * 50)
        }

        InitializePredefinedVariables $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)

        # If user does not supply the TemplatePath parameter, the dynamicparam scriptblock bails early without
        # loading the Plaster manifest.  If that's the case, load the manifest now.
        if ($null -eq $manifestPath) {
            $TemplatePath = ExtractTemplateAndReturnPath $TemplatePath
            $manifestPath = Join-Path $TemplatePath plasterManifest.xml
            $manifestPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($manifestPath)
        }

        # Validate that the dynamicparam scriptblock was able to load the template manifest and it is valid.
        if ($null -eq $manifest) {
            if (Test-Path $manifestPath) {
                $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop
            }
            else {
                throw ($LocalizedData.ManifestFileMissing_F1 -f $manifestPath)
            }
        }

        # Check for any existing default value store file and load default values if file exists.
        $templateId = $manifest.plasterManifest.metadata.id
        $templateVersion = $manifest.plasterManifest.metadata.version
        $templateBaseName = [System.IO.Path]::GetFileNameWithoutExtension($TemplatePath)
        $storeFilename = "$templateBaseName-$templateVersion-$templateId"
        $defaultValueStorePath = Join-Path $ParameterDefaultValueStoreRootPath $storeFilename
        if (Test-Path $defaultValueStorePath) {
            try {
                $PSCmdlet.WriteDebug("Loading default value store from '$defaultValueStorePath'.")
                $defaultValueStore = Import-Clixml $defaultValueStorePath -ErrorAction Stop
            }
            catch {
                Write-Warning ($LocalizedData.ErrorFailedToLoadStoreFile_F1 -f $defaultValueStorePath)
            }
        }

        function PromptForInput($prompt, $default) {
            do {
                $value = Read-Host -Prompt $prompt
                if (!$value -and $default) {
                    $value = $default
                }
            } while (!$value)

            $value
        }

        function PromptForChoice([ValidateNotNull()]$ChoiceNodes, [string]$prompt, [int[]]$defaults, [switch]$IsMultiChoice) {
            $choices = New-Object 'System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]'
            $values = New-Object object[] $ChoiceNodes.Count
            $i = 0

            foreach ($choiceNode in $ChoiceNodes) {
                $label = ExpandString $choiceNode.label
                $help = ExpandString $choiceNode.help
                $value = ExpandString $choiceNode.value

                $choice = New-Object System.Management.Automation.Host.ChoiceDescription -Arg $label,$help
                $choices.Add($choice)
                $values[$i++] = $value
            }

            $retval = [PSCustomObject]@{Values=@(); Indices=@()}

            if ($IsMultiChoice) {
                $selections = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults)
                foreach ($selection in $selections) {
                    $retval.Values += $values[$selection]
                    $retval.Indices += $selection
                }
            }
            else {
                if ($defaults.Count -gt 1) {
                    throw ($LocalizedData.ParameterTypeChoiceMultipleDefault_F1 -f $ChoiceNodes.ParentNode.name)
                }

                $selection = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults[0])
                $retval.Values = $values[$selection]
                $retval.Indices = $selection
            }

            $retval
        }

        function ProcessParameter([ValidateNotNull()]$Node) {
            $name = $Node.name
            $type = $Node.type
            $store = $Node.store
            $prompt = ExpandString $Node.prompt
            $default = ExpandString $Node.default

            # Check if parameter was provided via a dynamic parameter
            if ($boundParameters.ContainsKey($name)) {
                $value = $boundParameters[$name]
            }
            else {
                # Not a dynamic parameter so prompt user for the value but first check for a stored default value.
                if ($store -and ($null -ne $defaultValueStore[$name])) {
                    $default = $defaultValueStore[$name]
                    $PSCmdlet.WriteDebug("Read default value '$default' for parameter '$name' from default value store.")

                    if (($store -eq 'encrypted') -and ($default -is [System.Security.SecureString])) {
                        try {
                            $cred = New-Object -TypeName PSCredential -ArgumentList 'jsbplh',$default
                            $default = $cred.GetNetworkCredential().Password
                            $PSCmdlet.WriteDebug("Unencrypted default value for parameter '$name'.")
                        }
                        catch [System.Exception] {
                            Write-Warning ($LocalizedData.ErrorUnencryptingSecureString_F1 -f $name)
                        }
                    }
                }

                # Some default values might not come from the template e.g. some are harvested from .gitconfig if it exists
                $defaultNotFromTemplate = $false

                # Now prompt user for parameter value based on the parameter type
                switch -regex ($type) {
                    'text' {
                        # Display an appropriate "default" value in the prompt string.
                        if ($default) {
                            if ($store -eq 'encrypted') {
                                $obscuredDefault = $default -replace '(....).*', '$1****'
                                $prompt += " ($obscuredDefault)"
                            }
                            else {
                                $prompt += " ($default)"
                            }
                        }
                        # Prompt the user for text input.
                        $value = PromptForInput $prompt $default
                        $valueToStore = $value
                    }
                    'user-fullname' {
                        # If no default, try to get a name from git config
                        if (!$default) {
                            $default = GetGitConfigValue('name')
                            $defaultNotFromTemplate = $true
                        }

                        if ($default) {
                            if ($store -eq 'encrypted') {
                                $obscuredDefault = $default -replace '(....).*', '$1****'
                                $prompt += " ($obscuredDefault)"
                            }
                            else {
                                $prompt += " ($default)"
                            }
                        }

                        # Prompt the user for text input.
                        $value = PromptForInput $prompt $default
                        $valueToStore = $value
                    }
                    'user-email' {
                        # If no default, try to get an email from git config
                        if (-not $default) {
                            $default = GetGitConfigValue('email')
                            $defaultNotFromTemplate = $true
                        }

                        if ($default) {
                            if ($store -eq 'encrypted') {
                                $obscuredDefault = $default -replace '(....).*', '$1****'
                                $prompt += " ($obscuredDefault)"
                            }
                            else {
                                $prompt += " ($default)"
                            }
                        }

                        # Prompt the user for text input.
                        $value = PromptForInput $prompt $default
                        $valueToStore = $value
                    }
                    'choice|multichoice' {
                        $choices = $Node.ChildNodes
                        $defaults = [int[]]($default -split ',')

                        # Prompt the user for choice or multichoice selection input.
                        $selections = PromptForChoice $choices $prompt $defaults -IsMultiChoice:($type -eq 'multichoice')
                        $value = $selections.Values
                        $OFS = ","
                        $valueToStore = "$($selections.Indices)"
                    }
                    default  { throw ($LocalizedData.UnrecognizedParameterType_F2 -f $type, $Node.LocalName) }
                }

                # If parameter specifies that user's input be stored as the default value,
                # store it to file if the value has changed.
                if ($store -and (($default -ne $valueToStore) -or $defaultNotFromTemplate)) {
                    if ($store -eq 'encrypted') {
                        $PSCmdlet.WriteDebug("Storing new, encrypted default value for parameter '$name' to default value store.")
                        $defaultValueStore[$name] = ConvertTo-SecureString -String $valueToStore -AsPlainText -Force
                    }
                    else {
                        $PSCmdlet.WriteDebug("Storing new default value '$valueToStore' for parameter '$name' to default value store.")
                        $defaultValueStore[$name] = $valueToStore
                    }

                    $flags.DefaultValueStoreDirty = $true
                }
            }

            # Make template defined parameters available as a PowerShell variable PLASTER_PARAM_<parameterName>
            Set-Variable -Name "PLASTER_PARAM_$name" -Value $value -Scope Script -WhatIf:$false
        }

        function ProcessMessage([ValidateNotNull()]$Node) {
            $text = ExpandString $Node.InnerText
            $nonewline = ExpandString $Node.nonewline

            # Eliminate whitespace before and after the text that just happens to get inserted because you want
            # the text on different lines than the start/end element tags.
            $trimmedText = $text -replace '^[ \t]*\n','' -replace '\n[ \t]*$',''

            $condition  = $Node.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    $debugText = $trimmedText -replace '\r|\n',' '
                    $maxLength = [Math]::Min(40, $debugText.Length)
                    $PSCmdlet.WriteDebug("Skipping message '$($debugText.Substring(0, $maxLength))', condition evaluated to false.")
                    return
                }
            }

            Write-Host $trimmedText -NoNewline:($nonewline -eq 'true')
        }

        function GenerateModuleManifest([ValidateNotNull()]$Node) {
            $moduleVersion = ExpandString $Node.moduleVersion
            $rootModule = ExpandString $Node.rootModule
            $author = ExpandString $Node.author
            $companyName = ExpandString $Node.companyName
            $description = ExpandString $Node.description
            $dstRelPath = ExpandString $Node.destination
            $dstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $dstRelPath))

            $condition  = $Node.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    $PSCmdlet.WriteDebug("Skipping module manifest generation for '$dstPath', condition evaluated to false.")
                    return
                }
            }

            $encoding = ExpandString $Node.encoding
            if (!$encoding) {
                $encoding = $DefaultEncoding
            }

            if ($PSCmdlet.ShouldProcess($dstPath, $LocalizedData.ShouldProcessGenerateModuleManifest)) {
                $manifestDir = Split-Path $dstPath -Parent
                if (!(Test-Path $manifestDir)) {
                    VerifyPathIsUnderDestinationPath $manifestDir
                    Write-Verbose ($LocalizedData.NewModManifest_CreatingDir_F1 -f $manifestDir)
                    New-Item $manifestDir -ItemType Directory > $null
                }

                $newModuleManifestParams = @{}

                if (![string]::IsNullOrWhiteSpace($moduleVersion)) {
                    $newModuleManifestParams['ModuleVersion'] = $moduleVersion
                }
                if (![string]::IsNullOrWhiteSpace($rootModule)) {
                    $newModuleManifestParams['RootModule'] = $rootModule
                }
                if (![string]::IsNullOrWhiteSpace($author)) {
                    $newModuleManifestParams['Author'] = $author
                }
                if (![string]::IsNullOrWhiteSpace($companyName)) {
                    $newModuleManifestParams['CompanyName'] = $companyName
                }
                if (![string]::IsNullOrWhiteSpace($description)) {
                    $newModuleManifestParams['Description'] = $description
                }

                $tempFile = $null

                try {
                    $tempFile = [System.IO.Path]::GetTempPath() + "moduleManifest-" + [Guid]::NewGuid() + ".psd1"
                    $PSCmdlet.WriteDebug("Created temp file for new module manifest - $tempFile")
                    $newModuleManifestParams['Path'] = $tempFile

                    # Generate manifest into a temp file
                    New-ModuleManifest @newModuleManifestParams

                    # Typically the manifest is re-written with a new encoding (UTF8-NoBOM) because Git hates UTF-16
                    $content = Get-Content -LiteralPath $tempFile -Raw
                    WriteContentWithEncoding -Path $tempFile -Content $content -Encoding $encoding

                    CopyFileWithConflictDetection $tempFile $dstPath
                }
                finally {
                    if ($tempFile -and (Test-Path $tempFile)) {
                        Remove-Item -LiteralPath $tempFile
                        $PSCmdlet.WriteDebug("Removed temp file for new module manifest - $tempFile")
                    }
                }
            }
        }

        #
        # Begin ProcessFile helper methods
        #
        function AreFilesIdentical($Path1, $Path2) {
            $file1 = Get-Item -LiteralPath $Path1
            $file2 = Get-Item -LiteralPath $Path2

            if ($file1.Length -ne $file2.Length) {
                return $false
            }

            $hash1 = (Get-FileHash -LiteralPath $path1 -Algorithm SHA1).Hash
            $hash2 = (Get-FileHash -LiteralPath $path2 -Algorithm SHA1).Hash

            $hash1 -eq $hash2
        }

        function NewFileSystemCopyInfo([string]$srcPath, [string]$dstPath) {
            [PSCustomObject]@{SrcFileName=$srcPath; DstFileName=$dstPath}
        }

        function ExpandFileSourceSpec([string]$srcRelPath, [string]$dstRelPath) {
            $srcPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $TemplatePath $srcRelPath))
            $dstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $dstRelPath))

            if ($srcRelPath.IndexOfAny([char[]]('*','?')) -lt 0) {
                # No wildcard spec in srcRelPath so return info on single file
                return NewFileSystemCopyInfo $srcPath $dstPath
            }

            # Prepare parameter values for call to Get-ChildItem to get list of files based on wildcard spec
            $gciParams = @{}
            $parent = Split-Path $srcPath -Parent
            $leaf = Split-Path $srcPath -Leaf
            $gciParams['LiteralPath'] = $parent
            $gciParams['File'] = $true

            if ($leaf -eq '**') {
                $gciParams['Recurse'] = $true
            }
            else {
                if ($leaf.IndexOfAny([char[]]('*','?')) -ge 0) {
                    $gciParams['Filter'] = $leaf
                }

                $leaf = Split-Path $parent -Leaf
                if ($leaf -eq '**') {
                    $parent = Split-Path $parent -Parent
                    $gciParams['LiteralPath'] = $parent
                    $gciParams['Recurse'] = $true
                }
            }

            $srcRelRootPathLength = $gciParams['LiteralPath'].Length

            # Generate a FileCopyInfo object for every file expanded by the wildcard spec
            $files = @(Microsoft.PowerShell.Management\Get-ChildItem @gciParams)
            foreach ($file in $files) {
                $fileSrcPath = $file.FullName
                $relPath = $fileSrcPath.Substring($srcRelRootPathLength)
                $fileDstPath = Join-Path $dstPath $relPath
                NewFileSystemCopyInfo $fileSrcPath $fileDstPath
            }

            # Copy over empty directories - if any
            $gciParams.Remove('File')
            $gciParams['Directory'] = $true
            $dirs = @(Microsoft.PowerShell.Management\Get-ChildItem @gciParams | Where {$_.GetFileSystemInfos().Length -eq 0})
            foreach ($dir in $dirs) {
                $dirSrcPath = $dir.FullName
                $relPath = $dirSrcPath.Substring($srcRelRootPathLength)
                $dirDstPath = Join-Path $dstPath $relPath
                NewFileSystemCopyInfo $dirSrcPath $dirDstPath
            }
        }

        # Plaster zen for file handling.  All file related operations should use this method
        # to actually write/overwrite/modify files in the DestinationPath.  This method
        # handles detecting conflicts, gives the user a chance to determine how to handle
        # conflicts.  The user can choose to use the Force parameter to force the overwriting
        # of existing files at the destination path.
        # File processing (expanding substitution variable, modifying file contents) should always
        # be done to a temp file (be sure to always remove temp file when done).  That temp file
        # is what gets passed to this function as the $SrcPath.  This allows Plaster to alert the
        # user when the repeated application of a template will modify any existing file.
        # NOTE: Plaster keeps track of which files it has "created" (as opposed to overwritten)
        # so that any later change to that file doesn't trigger conflict handling.
        function CopyFileWithConflictDetection([string]$SrcPath, [string]$DstPath) {
            # Just double-checking that DstPath parameter is an absolute path otherwise
            # it could fail the check that the DstPath is under the overall DestinationPath.
            if (![System.IO.Path]::IsPathRooted($DstPath)) {
                $DstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DstPath)
            }

            # Check if DstPath file conflicts with an existing SrcPath file.
            $operation = $LocalizedData.OpCreate
            $opmessage = (ConvertToDestinationRelativePath $DstPath)
            if (Test-Path -LiteralPath $DstPath) {
                if (AreFilesIdentical $SrcPath $DstPath) {
                    $operation = $LocalizedData.OpIdentical
                }
                elseif ($templateCreatedFiles.ContainsKey($DstPath)) {
                    # Plaster created this file previously during template invocation
                    # therefore, there is no conflict.  We're simply updating the file.
                    $operation = $LocalizedData.OpUpdate
                }
                elseif ($Force) {
                    $operation = $LocalizedData.OpForce
                }
                else  {
                    $operation = $LocalizedData.OpConflict
                }
            }

            # Copy the file to the destination
            if ($PSCmdlet.ShouldProcess($DstPath, $operation)) {
                WriteOperationStatus $operation $opmessage

                if ($operation -eq $LocalizedData.OpIdentical) {
                    # If the files are identical, no need to do anything
                    return
                }

                if (($operation -eq $LocalizedData.OpCreate) -or ($operation -eq $LocalizedData.OpUpdate)) {
                    Copy-Item -LiteralPath $SrcPath -Destination $DstPath
                    $templateCreatedFiles[$DstPath] = $null
                }
                elseif ($Force -or $PSCmdlet.ShouldContinue(($LocalizedData.OverwriteFile_F1 -f $DstPath),
                                                             $LocalizedData.FileConflict,
                                                             [ref]$fileConflictConfirmYesToAll,
                                                             [ref]$fileConflictConfirmNoToAll)) {
                    Copy-Item -LiteralPath $SrcPath -Destination $DstPath
                    $templateCreatedFiles[$DstPath] = $null
                }
            }
        }

        #
        # End ProcessFile helper methods
        #

        # Processes both the <file> and <templateFile> directives.
        function ProcessFile([ValidateNotNull()]$Node) {
            $srcRelPath = ExpandString $Node.source
            $dstRelPath = ExpandString $Node.destination

            $condition  = $Node.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    $PSCmdlet.WriteDebug("Skipping $($Node.localName) '$srcRelPath' -> '$dstRelPath', condition evaluated to false.")
                    return
                }
            }

            # Check if node is the specialized, <templateFile> node.
            # Only <templateFile> nodes expand templates and use the encoding attribute.
            $isTemplateFile = $Node.localName -eq 'templateFile'
            if ($isTemplateFile) {
                $encoding = ExpandString $Node.encoding
                if (!$encoding) {
                    $encoding = $DefaultEncoding
                }
            }

            # Check if source specifies a wildcard and if so, expand the wildcard
            # and then process each file system object (file or empty directory).
            $fileSystemCopyInfoObjs = ExpandFileSourceSpec $srcRelPath $dstRelPath
            foreach ($fileSystemCopyInfo in $fileSystemCopyInfoObjs) {
                $srcPath = $fileSystemCopyInfo.SrcFileName
                $dstPath = $fileSystemCopyInfo.DstFileName

                # Check to see if we're copying an empty dir
                if (Test-Path -LiteralPath $srcPath -PathType Container) {
                    if (!(Test-Path -LiteralPath $dstPath)) {
                        if ($PSCmdlet.ShouldProcess($parentDir, $LocalizedData.ShouldProcessCreateDir)) {
                            New-Item -Path $dstPath -ItemType Directory > $null
                        }
                    }

                    continue
                }

                # If the file's parent dir doesn't exist, create it.
                $parentDir = Split-Path $dstPath -Parent
                if (!(Test-Path -LiteralPath $parentDir)) {
                    if ($PSCmdlet.ShouldProcess($parentDir, $LocalizedData.ShouldProcessCreateDir)) {
                        New-Item -Path $parentDir -ItemType Directory > $null
                    }
                }

                $tempFile = $null

                try {
                    # If processing a <templateFile>, copy to a temp file to expand the template file,
                    # then apply the normal file conflict detection/resolution handling.
                    $target = $LocalizedData.TempFileTarget_F1 -f (ConvertToDestinationRelativePath $dstPath)
                    if ($isTemplateFile -and $PSCmdlet.ShouldProcess($target, $LocalizedData.ShouldProcessExpandTemplate)) {

                        $content = Get-Content -LiteralPath $srcPath -Raw
                        $pattern = '(<%=)(.*?)(%>)'
                        $newContent = [regex]::Replace($content, $pattern, {
                            param($match)
                            $expr = $match.groups[2].value
                            $res = ExpandString $expr
                            $PSCmdlet.WriteDebug("Replacing '$expr' with '$res' in contents of template file '$srcPath'")
                            $res
                        },  @('IgnoreCase', 'SingleLine', 'MultiLine'))

                        $srcPath = $tempFile = [System.IO.Path]::GetTempFileName()
                        $PSCmdlet.WriteDebug("Created temp file for expanded templateFile - $tempFile")

                        WriteContentWithEncoding -Path $tempFile -Content $newContent -Encoding $encoding
                    }

                    CopyFileWithConflictDetection $srcPath $dstPath
                }
                finally {
                    if ($tempFile -and (Test-Path $tempFile)) {
                        Remove-Item -LiteralPath $tempFile
                        $PSCmdlet.WriteDebug("Removed temp file for expanded templateFile - $tempFile")
                    }
                }
            }
        }

        function ModifyFile([ValidateNotNull()]$Node) {
            $path = ExpandString $Node.path
            $filePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $path))

            $PLASTER_FileContent = ''
            if (Test-Path $filePath) {
                $PLASTER_FileContent = Get-Content -LiteralPath $filePath -Raw
            }

            $condition  = $Node.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    $PSCmdlet.WriteDebug("Skipping $($Node.LocalName) of '$filePath', condition evaluated to false.")
                    return
                }
            }

            $encoding = ExpandString $Node.encoding
            if (!$encoding) {
                $encoding = $DefaultEncoding
            }

            # If processing a <modify> directive, write the modified contents to a temp file,
            # then apply the normal file conflict detection/resolution handling.
            $target = $LocalizedData.TempFileTarget_F1 -f $filePath
            if ($PSCmdlet.ShouldProcess($target, $LocalizedData.OpModify)) {
                WriteOperationStatus $LocalizedData.OpModify ($LocalizedData.TempFileOperation_F1 -f (ConvertToDestinationRelativePath $filePath))

                $modified = $false

                foreach ($childNode in $Node.ChildNodes) {
                    if ($childNode -isnot [System.Xml.XmlElement]) { continue }

                    switch ($childNode.LocalName) {
                        'replace' {
                            $condition  = $childNode.condition
                            if ($condition) {
                                if (!(EvaluateCondition $condition)) {
                                    $PSCmdlet.WriteDebug("Skipping $($Node.LocalName) $($childNode.LocalName) of '$filePath', condition evaluated to false.")
                                    continue
                                }
                            }

                            if ($childNode.original -is [string]) {
                                $original = $childNode.original
                            }
                            else {
                                $original = $childNode.original.InnerText
                            }

                            if ($childNode.original.expand -eq 'true') {
                                $original = ExpandString $original
                            }

                            if ($childNode.substitute -is [string]) {
                                $substitute = $childNode.substitute
                            }
                            else {
                                $substitute = $childNode.substitute.InnerText
                            }

                            if ($childNode.substitute.expand -eq 'true') {
                                $substitute = ExpandString $substitute
                            }

                            $PLASTER_FileContent = $PLASTER_FileContent -replace $original,$substitute

                            $modified = $true
                        }
                        default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $childNode.LocalName) }
                    }
                }

                $tempFile = $null

                try {
                    # We could use CopyFileWithConflictDetection to handle the "identical" (not modified) case
                    # but if nothing was changed, I'd prefer not to generate a temp file, copy the unmodified contents
                    # into that temp file with hopefully the right encoding and then potentially overwrite the original file
                    # (different encoding will make the files look different) with the same contents but different encoding.
                    # If the intent of the <modify> was simple to change an existing file's encoding then the directive will
                    # need to make a whitespace change to the file.
                    if ($modified) {
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        $PSCmdlet.WriteDebug("Created temp file for modified file - $tempFile")

                        WriteContentWithEncoding -Path $tempFile -Content $PLASTER_FileContent -Encoding $encoding
                        CopyFileWithConflictDetection $tempFile $filePath
                    }
                    else {
                        WriteOperationStatus $LocalizedData.OpIdentical (ConvertToDestinationRelativePath $filePath)
                    }
                }
                finally {
                    if ($tempFile -and (Test-Path $tempFile)) {
                        Remove-Item -LiteralPath $tempFile
                        $PSCmdlet.WriteDebug("Removed temp file for modified file - $tempFile")
                    }
                }
            }
        }
    }

    end {
        # Process parameters
        foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
            if ($node -isnot [System.Xml.XmlElement]) { continue }
            switch ($node.LocalName) {
                'parameter'  { ProcessParameter $node }
                default      { throw ($LocalizedData.UnrecognizedParametersElement_F1 -f $node.LocalName) }
            }
        }

        # Outputs the processed template parameters to the debug stream
        $parameters = Get-Variable -Name PLASTER_* | Out-String
        $PSCmdlet.WriteDebug("Parameter values are:`n$($parameters -split "`n")")

        # Stores any updated default values back to the store file.
        if ($flags.DefaultValueStoreDirty) {
            $directory = Split-Path $defaultValueStorePath -Parent
            if (!(Test-Path $directory)) {
                $PSCmdlet.WriteDebug("Creating directory for template's DefaultValueStore '$directory'.")
                New-Item $directory -ItemType Directory > $null
            }

            $PSCmdlet.WriteDebug("DefaultValueStore is dirty, saving updated values to '$defaultValueStorePath'.")
            $defaultValueStore | Export-Clixml -LiteralPath $defaultValueStorePath
        }

        # Process content
        foreach ($node in $manifest.plasterManifest.content.ChildNodes) {
            if ($node -isnot [System.Xml.XmlElement]) { continue }

            switch -Regex ($node.LocalName) {
                'file|templateFile' { ProcessFile $node; break }
                'message'           { ProcessMessage $node; break }
                'modify'            { ModifyFile $node; break }
                'newModuleManifest' { GenerateModuleManifest $node; break }
                default             { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
            }
        }
    }
}


<#
██   ██ ███████ ██      ██████  ███████ ██████  ███████
██   ██ ██      ██      ██   ██ ██      ██   ██ ██
███████ █████   ██      ██████  █████   ██████  ███████
██   ██ ██      ██      ██      ██      ██   ██      ██
██   ██ ███████ ███████ ██      ███████ ██   ██ ███████
#>

function InitializePredefinedVariables([string]$destPath) {
    # Always set these variables, even if the command has been run with -WhatIf
    $WhatIfPreference = $false

    $destName = Split-Path -Path $destPath -Leaf
    Set-Variable -Name PLASTER_DestinationPath -Value $destPath.TrimEnd('\','/') -Scope Script
    Set-Variable -Name PLASTER_DestinationName -Value $destName -Scope Script

    Set-Variable -Name PLASTER_Guid1 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid2 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid3 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid4 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid5 -Value ([Guid]::NewGuid()) -Scope Script

    $now = [DateTime]::Now
    Set-Variable -Name PLASTER_Date -Value ($now.ToShortDateString()) -Scope Script
    Set-Variable -Name PLASTER_Time -Value ($now.ToShortTimeString()) -Scope Script
    Set-Variable -Name PLASTER_Year -Value ($now.Year) -Scope Script
}

function ExpandString($str) {
    if ($null -eq $str) {
        return [string]::Empty
    }
    elseif ([string]::IsNullOrWhiteSpace($str)) {
        return $str
    }

    # There are at least two ways to go to provide "safe" string evaluation with *only* variable
    # expansion and not arbitrary script execution via subexpressions.  We could a regex to pull
    # out a variable name e.g. '\$\{(.*?)\}', then use
    # [System.Management.Automation.Language.CodeGeneration]::EscapeVariableName followed by
    # $ExecutionContext.InvokeCommand.ExpandString().  The other way to go is to pick a specific part
    # of the AST and vet it before using $ExecutionContext.InvokeCommand.ExpandString().

    # TODO: fix issue with input containing `$1 (regex substitution group) getting eliminated by Expression.Value

    $sb = [scriptblock]::Create("`"$str`"")

    $endBlockAst = $sb.Ast.EndBlock.Statements[0].PipelineElements[0]
    if ($endBlockAst -isnot [System.Management.Automation.Language.CommandExpressionAst]) {
        throw ($LocalizedData.SubsitutionExpressionInvalid_F1 -f $endBlockAst.Extent.Text)
    }

    if ($endBlockAst.Expression -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
        $evalStr = $endBlockAst.Expression.Value
    }
    elseif ($endBlockAst.Expression -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
        foreach ($nestedExpr in $endBlockAst.Expression.NestedExpressions) {
            if ($nestedExpr -isnot [System.Management.Automation.Language.VariableExpressionAst]) {
                throw ($LocalizedData.SubsitutionExpressionInvalid_F1 -f $endBlockAst.Extent.Text)
            }
        }

        $evalStr = $endBlockAst.Expression.Value
    }
    else {
        throw ($LocalizedData.SubsitutionExpressionInvalid_F1 -f $endBlockAst.Extent.Text)
    }

    $ExecutionContext.InvokeCommand.ExpandString($evalStr)
}

function EvaluateCondition([string]$expr) {
    # TODO: Yeah, this is *not* a safe eval function - yet.

    $sb = [scriptblock]::Create($expr)
    $res = $sb.Invoke()
    [bool]$res
}

function ConvertToDestinationRelativePath($Path) {
    $fullDestPath = $DestinationPath
    if (![System.IO.Path]::IsPathRooted($fullDestPath)) {
        $fullDestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    }

    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (!$fullPath.StartsWith($fullDestPath, 'OrdinalIgnoreCase')) {
        throw ($LocalizedData.ErrorPathMustBeUnderDestPath_F2 -f $fullPath, $fullDestPath)
    }

    $fullPath.Substring($fullDestPath.Length).TrimStart('\','/')
}

function VerifyPathIsUnderDestinationPath([ValidateNotNullOrEmpty()][string]$FullPath) {
    if (![System.IO.Path]::IsPathRooted($FullPath)) {
        Write-Debug "The FullPath parameter '$FullPath' must be an absolute path."
    }

    $fullDestPath = $DestinationPath
    if (![System.IO.Path]::IsPathRooted($fullDestPath)) {
        $fullDestPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    }

    if (!$FullPath.StartsWith($fullDestPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw ($LocalizedData.ErrorPathMustBeUnderDestPath_F2 -f $FullPath, $fullDestPath)
    }
}

function WriteContentWithEncoding([string]$path, [string[]]$content, [string]$encoding) {
    if ($encoding -match '-nobom') {
        $encoding,$dummy = $encoding -split '-'

        $noBomEncoding = $null
        switch ($encoding) {
            'utf8' { $noBomEncoding = New-Object System.Text.UTF8Encoding($false) }
        }

        if ($content -eq $null) {
            $content = [string]::Empty
        }

        [System.IO.File]::WriteAllLines($path, $content, $noBomEncoding)
    }
    else {
        Set-Content -LiteralPath $path -Value $content -Encoding $encoding
    }
}

function ColorForOperation($operation) {
    switch ($operation) {
        $LocalizedData.OpConflict  { 'Red' }
        $LocalizedData.OpCreate    { 'Green' }
        $LocalizedData.OpForce     { 'Yellow' }
        $LocalizedData.OpIdentical { 'Cyan' }
        $LocalizedData.OpModify    { 'Magenta' }
        $LocalizedData.OpUpdate    { 'Green' }
        default { $Host.UI.RawUI.ForegroundColor }
    }
}

function WriteOperationStatus($operation, $message) {
    $maxLen = ($LocalizedData.OpCreate,   $LocalizedData.OpIdentical,
               $LocalizedData.OpConflict, $LocalizedData.OpForce,
               $LocalizedData.OpModify,   $LocalizedData.OpUpate |
                  Measure-Object -Property Length -Maximum).Maximum

    Write-Host ("{0,$maxLen} " -f $operation) -ForegroundColor (ColorForOperation $operation) -NoNewline
    Write-Host $message
}

function GetGitConfigValue($name) {
    # Very simplistic git config lookup
    # Won't work with namespace, just use final element, e.g. 'name' instead of 'user.name'
    $gitConfigPath = (Join-Path $env:Home '.gitconfig')
    Write-Debug "Looking for '$name' value in Git config: $gitConfigPath"
    if (Test-Path -LiteralPath $gitConfigPath) {
        $matches = Select-String -LiteralPath $gitConfigPath -Pattern "\s+$name\s+=\s+(.+)$"
        if (@($matches).Count -gt 0)
        {
            $matches.Matches.Groups[1].Value
        }
    }
}
