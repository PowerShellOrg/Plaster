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
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='GenerateModuleManifest')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ProcessTemplate')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ModifyFile')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ProcessFile')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidShouldContinueWithoutForce', '', Scope='Function', Target='ProcessFile')]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        # Specifies the path to either the Template directory or a ZIP file containing the template.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath,

        # Specifies the path to directory in which the template will use as a root directory when generating files.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        # Specify Force to override user prompts for conflicting handling.  This will override the confirmation
        # prompt and allow the template to over write existing files.
        [Parameter()]
        [switch]
        $Force
    )

    # Process the template's plaster manifest file to convert parameters defined there into dynamic parameters.
    dynamicparam {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $manifest = $null
        $manifestPath = $null

        if ($null -eq $TemplatePath) {
            # Can't process dynamic parameters if we have no TemplatePath
            return
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

                switch ($type) {
                    'input' {
                        $param = New-Object System.Management.Automation.RuntimeDefinedParameter `
                                     -ArgumentList ($name, [string], $attributeCollection)
                        break
                    }

                    { 'choice','multichoice' -contains $_ } {
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

        $randLogo = $logo[(Get-Random -Minimum 0 -Maximum $logo.Length)]
        Write-Host $randLogo
        Write-Host ("=" * 50)

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

        function ProcessParameter([ValidateNotNull()]$ParamNode) {
            $name = $ParamNode.name
            $type = $ParamNode.type
            $store = $ParamNode.store
            $prompt = ExpandString $ParamNode.prompt
            $default = ExpandString $ParamNode.default

            # Check if parameter was provided via a dynamic parameter
            if ($boundParameters.ContainsKey($name)) {
                $value = $boundParameters[$name]
            }
            else {
                # Not a dynamic parameter so prompt user for the value but first check for a stored default value.
                if ($store -and ($null -ne $defaultValueStore[$name])) {
                    $default = $defaultValueStore[$name]
                    $PSCmdlet.WriteDebug("Read default value '$default' for parameter '$name'.")

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

                # Now prompt user for parameter value
                switch -regex ($type) {
                    'input' {
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
                    'author' {
                        # If no default, try to get a name from git config
                        if (-not $default) {
                            $default = GetGitConfigValue('name')
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
                    'email' {
                        # If no default, try to get an email from git config
                        if (-not $default) {
                            $default = GetGitConfigValue('email')
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
                        $choices = $ParamNode.ChildNodes
                        $defaults = [int[]]($default -split ',')

                        # Prompt the user for choice or multichoice selection input.
                        $selections = PromptForChoice $choices $prompt $defaults -IsMultiChoice:($type -eq 'multichoice')
                        $value = $selections.Values
                        $OFS = ","
                        $valueToStore = "$($selections.Indices)"
                    }
                    default  { throw ($LocalizedData.UnrecognizedAttribute_F2 -f $type, $ParamNode.LocalName) }
                }

                # If parameter specifies that user's input be stored as the default value,
                # store it to file if the value has changed.
                if ($store -and ($default -ne $valueToStore)) {
                    if ($store -eq 'encrypted') {
                        $PSCmdlet.WriteDebug("Storing new, encrypted default value for parameter '$name'.")
                        $defaultValueStore[$name] = ConvertTo-SecureString -String $valueToStore -AsPlainText -Force
                    }
                    else {
                        $PSCmdlet.WriteDebug("Storing new default value '$valueToStore' for parameter '$name'.")
                        $defaultValueStore[$name] = $valueToStore
                    }

                    $flags.DefaultValueStoreDirty = $true
                }
            }

            # Make template defined parameters available as a PowerShell variable PLASTER_PARAM_<parameterName>
            Set-Variable -Name "PLASTER_PARAM_$name" -Value $value -Scope Script
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
                    Write-Verbose "Skipping message '$($text[0..40])', condition evaluated to false."
                    return
                }
            }

            Write-Host $trimmedText -NoNewline:($nonewline -eq 'true')
        }

        function GenerateModuleManifest([ValidateNotNull()]$NewModuleManifestNode) {
            $moduleVersion = ExpandString $NewModuleManifestNode.moduleVersion
            $rootModule = ExpandString $NewModuleManifestNode.rootModule
            $author = ExpandString $NewModuleManifestNode.author
            $dstRelPath = ExpandString $NewModuleManifestNode.destination
            $dstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $dstRelPath))

            $condition  = $NewModuleManifestNode.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    Write-Verbose "Skipping module manifest generation for '$dstPath', condition evaluated to false."
                    return
                }
            }

            $encoding = ExpandString $NewModuleManifestNode.encoding
            if (!$encoding) {
                $encoding = $DefaultEncoding
            }

            # TODO: This generates a file and as such should participate in file
            # conflict resolution. I think we should gen the file here and then
            # use the normal ProcessFile (or function used by ProcessFile) to handle file conflicts.
            if ($PSCmdlet.ShouldProcess($dstPath, $LocalizedData.ShouldProcessGenerateModuleManifest)) {
                $manifestDir = Split-Path $dstPath -Parent
                if (!(Test-Path $manifestDir)) {
                    # TODO: Create a function for this that tests that the directory is under
                    #       the destination directory.
                    Write-Verbose "Creating destination dir for module manifest: $manifestDir"
                    New-Item $manifestDir -ItemType Directory > $null
                }

                # TODO: Temporary - remove this when this function makes use of ProcessFile
                WriteOperationStatus 'Create' (ConvertToDestinationRelativePath $dstPath)

                New-ModuleManifest -Path $dstPath -ModuleVersion $moduleVersion -RootModule $rootModule -Author $author
                $content = Get-Content -LiteralPath $dstPath -Raw
                WriteContentWithEncoding -Path $dstPath -Content $content -Encoding $encoding
            }
        }

        function ProcessTemplate([string]$Path, $encoding) {
            if ($PSCmdlet.ShouldProcess($Path, $LocalizedData.ShouldProcessTemplateFile)) {
                $content = Get-Content $Path -Raw
                $pattern = '(<%=)(.*?)(%>)'
                $newContent = [regex]::Replace($content, $pattern, {
                    param($match)
                    $expr = $match.groups[2].value
                    Write-Verbose "Replacing template expr $expr in '$Path'"
                    ExpandString $expr
                },  @('IgnoreCase', 'SingleLine', 'MultiLine'))

                WriteContentWithEncoding -Path $Path -Content $newContent -Encoding $encoding
            }
        }

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

        function NewFileCopyInfo([string]$srcPath, [string]$dstPath) {
            [PSCustomObject]@{SrcFileName=$srcPath; DstFileName=$dstPath}
        }

        function ExpandFileSourceSpec([string]$srcRelPath, [string]$dstRelPath) {
            $dstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $dstRelPath))

            if ($srcRelPath.IndexOfAny([char[]]('*','?')) -lt 0) {
                # No wildcard spec in srcRelPath so return info on single file
                $srcPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $TemplatePath $srcRelPath))
                return NewFileCopyInfo $srcPath $dstPath
            }

            # Prepare parameter values for call to Get-ChildItem to get list of files based on wildcard spec
            $gciParams = @{}
            $srcPath = Join-Path $TemplatePath $parent
            $parent = Split-Path $srcPath -Parent
            $leaf = Split-Path $srcPath -Leaf
            $gciParams['LiteralPath'] = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($parent)
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
                    $gciParams['LiteralPath'] = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($parent)
                    $gciParams['Recurse'] = $true
                }
            }

            $srcRelRootPathLength = $gciParams['LiteralPath'].Length

            # Generate a FileCopyInfo object for every file expanded by the wildcard spec
            $files = Microsoft.PowerShell.Management\Get-ChildItem @gciParams
            foreach ($file in $files) {
                $fileSrcPath = $file.FullName
                $relPath = $fileSrcPath.Substring($srcRelRootPathLength)
                $fileDstPath = Join-Path $dstPath $relPath
                NewFileCopyInfo $fileSrcPath $fileDstPath
            }
        }

        function ProcessFile([ValidateNotNull()]$FileNode) {
            $srcRelPath = ExpandString $FileNode.source
            $dstRelPath = ExpandString $FileNode.destination

            $condition  = $FileNode.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    Write-Verbose "Skipping file '$dstRelPath', condition evaluated to false."
                    return
                }
            }

            $isTemplate = $FileNode.template -eq 'true'
            $encoding = ExpandString $FileNode.encoding
            if (!$encoding) {
                $encoding = $DefaultEncoding
            }

            $fileCopyInfoObjs = ExpandFileSourceSpec $srcRelPath $dstRelPath
            foreach ($fileCopyInfo in $fileCopyInfoObjs) {
                $srcPath = $fileCopyInfo.SrcFileName
                $dstPath = $fileCopyInfo.DstFileName

                # If the file's parent dir doesn't exist, create it.
                $parentDir = Split-Path $dstPath -Parent
                if (!(Test-Path $parentDir)) {
                    if ($PSCmdlet.ShouldProcess($parentDir, $LocalizedData.ShouldProcessCreateDir)) {
                        New-Item -Path $parentDir -ItemType Directory > $null
                    }
                }

                $tempFile = $null

                try {
                    # If file is a template, copy to a temp file to process the template
                    if ($isTemplate) {
                        WriteOperationStatus $LocalizedData.OpExpand (ConvertToDestinationRelativePath $dstPath)

                        $tempFile = [System.IO.Path]::GetTempFileName()
                        Copy-Item -LiteralPath $srcPath -Destination $tempFile

                        ProcessTemplate $tempFile $encoding
                        $srcPath = $tempFile
                    }

                    # Check if new file (potentially after expansion) conflicts with corresponding existing file.
                    $operation = $LocalizedData.OpCreate
                    if (Test-Path $dstPath) {
                        if (AreFilesIdentical $srcPath $dstPath) {
                            $operation = $LocalizedData.OpIdentical
                        }
                        else {
                            $operation = $LocalizedData.OpConflict
                        }
                    }

                    # Copy the file to the destination
                    if ($PSCmdlet.ShouldProcess($dstPath, $operation)) {
                        WriteOperationStatus $operation (ConvertToDestinationRelativePath $dstPath)
                        if ($operation -ne $LocalizedData.OpConflict) {
                            Copy-Item -LiteralPath $srcPath -Destination $dstPath
                        }
                        elseif ($Force -or $PSCmdlet.ShouldContinue(($LocalizedData.OverwriteFile_F1 -f $dstPath),
                                                                    $LocalizedData.FileConflict,
                                                                    [ref]$fileConflictConfirmYesToAll,
                                                                    [ref]$fileConflictConfirmNoToAll)) {
                            Copy-Item -LiteralPath $srcPath -Destination $dstPath
                        }
                    }
                }
                finally {
                    if ($tempFile) {
                        Remove-Item -LiteralPath $tempFile
                    }
                }
            }
        }

        function ModifyFile([ValidateNotNull()]$ModifyNode) {
            $path = ExpandString $ModifyNode.path
            $filePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $path))

            $PLASTER_FileContent = ''
            if (Test-Path $filePath) {
                $PLASTER_FileContent = Get-Content -LiteralPath $filePath -Raw
            }

            $condition  = $ModifyNode.condition
            if ($condition) {
                if (!(EvaluateCondition $condition)) {
                    Write-Verbose "Skipping file modify on '$path', condition evaluated to false."
                    return
                }
            }

            $encoding = ExpandString $ModifyNode.encoding
            if (!$encoding) {
                $encoding = $DefaultEncoding
            }

            if ($PSCmdlet.ShouldProcess($filePath, $LocalizedData.ShouldProcessModifyContent)) {
                WriteOperationStatus $LocalizedData.OpModify (ConvertToDestinationRelativePath $filePath)

                $modified = $false

                foreach ($node in $ModifyNode.ChildNodes) {
                    if ($node -isnot [System.Xml.XmlElement]) { continue }

                    switch ($node.LocalName) {
                        'replace' {
                            $condition  = $node.condition
                            if ($condition) {
                                if (!(EvaluateCondition $condition)) {
                                    Write-Verbose "Skipping file modify replace on '$path', condition evaluated to false."
                                    continue
                                }
                            }

                            if ($node.original -is [string]) {
                                $original = $node.original
                            }
                            else {
                                $original = $node.original.InnerText
                            }

                            if ($node.original.expand -eq 'true') {
                                $original = ExpandString $original
                            }

                            if ($node.substitute -is [string]) {
                                $substitute = $node.substitute
                            }
                            else {
                                $substitute = $node.substitute.InnerText
                            }

                            if ($node.substitute.expand -eq 'true') {
                                $substitute = ExpandString $substitute
                            }

                            $PLASTER_FileContent = $PLASTER_FileContent -replace $original,$substitute

                            $modified = $true
                        }
                        default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
                    }
                }

                # TODO: write to temp file and introduce file conflict handling

                if ($modified) {
                    WriteContentWithEncoding -Path $filePath -Content $PLASTER_FileContent -Encoding $encoding
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

        # Outputs the processed template parameters to the verbose stream
        $parameters = Get-Variable -Name PLASTER_* | Out-String
        Write-Verbose "Parameter values are:`n$($parameters -split "`n")"

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

            switch ($node.LocalName) {
                'file'              { ProcessFile $node; break }
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
        return ''
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
        throw "$Path must contain $fullDestPath"
    }

    $fullPath.Substring($fullDestPath.Length).TrimStart('\','/')
}

function ColorForOperation($operation) {
    switch ($operation) {
        $LocalizedData.OpConflict  { 'Red' }
        $LocalizedData.OpCreate    { 'Green' }
        $LocalizedData.OpExpand    { 'Green' }
        $LocalizedData.OpIdentical { 'Cyan' }
        $LocalizedData.OpModify    { 'Green' }
        default { $Host.UI.RawUI.ForegroundColor }
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

function WriteOperationStatus($operation, $message) {
    $maxLen = ($LocalizedData.OpCreate, $LocalizedData.OpIdentical,
               $LocalizedData.OpConflict, $LocalizedData.OpExpand,
               $LocalizedData.OpModify | Measure-Object -Property Length -Maximum).Maximum

    Write-Host ("{0,$maxLen} " -f $operation) -ForegroundColor (ColorForOperation $operation) -NoNewline
    Write-Host $message
}

function GetGitConfigValue($name) {
    # Very simplistic git config lookup
    # Won't work with namespace, just use final element, e.g. 'name' instead of 'user.name'
    $gitConfigPath = (Join-Path $env:Home '.gitconfig')
    Write-Verbose "Looking for '$name' value in Git Config: $gitConfigPath"
    if (Test-Path $gitConfigPath) {
        $matches = Select-String -Path $gitConfigPath -Pattern "\s+$name\s+=\s+(.+)$"
        if (@($matches).Count -gt 0)
        {
            $matches.Matches.Groups[1].Value
        }
    }
}
