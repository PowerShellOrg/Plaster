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
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ProcessFile')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ProcessTemplate')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function', Target='ReplaceContent')]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        [Parameter()]
        [switch]
        $Force
    )

    dynamicparam {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        try {
            $manifestPath = Join-Path $TemplatePath 'plasterManifest.xml'
            $manifest = [xml](Get-Content $manifestPath -ErrorAction SilentlyContinue)

            # The user-defined parameters in the Plaster manifest are converted to dynamic parameters
            # which allows the user to provide all required parameters via the command line.
            # This enables non-interactive use cases.
            foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement] -and ($node.LocalName -eq 'parameter')) {
                    continue
                }

                $name = $node.name
                $type = $node.type
                $prompt = $node.prompt
                $default = $node.default

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
                        $choiceNodes = $node.SelectNodes('choice')
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
            Write-Warning ($LocalizedData.ErrorProcessingDynamicParams_F1 -f $_)
        }

        $paramDictionary
    }

    begin {
        $parameters = @{}
        $boundParameters = $PSBoundParameters
        $confirmYesToAll = $false
        $confirmNoToAll = $false

        InitializePredefinedVariables

        function GetManifest() {
            $manifestPath = Join-Path $TemplatePath 'plasterManifest.xml'
            if (!(Test-Path $manifestPath)) {
                throw "Missing manifest file: '$manifestPath'"
            }

            Plaster\Test-PlasterManifest -LiteralPath $manifestPath -ErrorAction Stop

            # TODO: This is redundant.  Test-PlasterManifest already loads the manifest.
            # If it returned the manifest, then we wouldn't need to load it again here.
            # That said, I don't want to have Test-PlasterManifest does this *just* to
            # eliminate the next six lines of script.
            try {
                $manifest = [xml](Get-Content $manifestPath)
            }
            catch {
                throw ($LocalizedData.ManifestNotValidXml_F1 -f $manifestPath)
            }

            $manifest
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

                if (!$label) {
                    throw ($LocalizedData.ManifestMissingAttribute_F2 -f $choiceNode.LocalName, 'help')
                }
                if (!$value) {
                    throw ($LocalizedData.ManifestMissingAttribute_F2 -f $choiceNode.LocalName, 'value')
                }

                $choice = New-Object System.Management.Automation.Host.ChoiceDescription -Arg $label,$help
                $choices.Add($choice)
                $values[$i++] = $value
            }

            if ($IsMultiChoice) {
                $selections = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults)
                foreach ($selection in $selections) {
                    $values[$selection]
                }
            }
            else {
                if ($defaults.Count -gt 1) {
                    throw ($LocalizedData.ParameterTypeChoiceMultipleDefault_F1 -f $ChoiceNodes.ParentNode.name)
                }

                $selection = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults[0])
                $values[$selection]
            }
        }

        function ProcessParameter([ValidateNotNull()]$ParamNode) {
            $name = $ParamNode.name
            $type = $ParamNode.type
            $prompt = ExpandString $ParamNode.prompt
            $default = ExpandString $ParamNode.default

            if (!$name) {
                throw ($LocalizedData.ManifestMissingAttribute_F2 -f $ParamNode.LocalName, 'name')
            }
            if (!$type) {
                throw ($LocalizedData.ManifestMissingAttribute_F2 -f $ParamNode.LocalName, 'type')
            }
            if (!$prompt) {
                throw ($LocalizedData.ManifestMissingAttribute_F2 -f $ParamNode.LocalName, 'prompt')
            }

            # Check if parameter was provided via a dynamic parameter
            if ($boundParameters.ContainsKey($name)) {
                $value =  $boundParameters[$name]
            }
            else {
                # Not a dynamic parameter so prompt user for the value
                $value = switch -regex ($type) {
                    'input'  {
                        if ($null -ne $default) {
                            $prompt += " ($default)"
                        }
                        PromptForInput $prompt $default
                    }
                    'choice|multichoice' {
                        $choices = $ParamNode.SelectNodes('choice')
                        $defaults = [int[]]($default -split ',')
                        PromptForChoice $choices $prompt $defaults -IsMultiChoice:($type -eq 'multichoice')
                    }
                    default  { throw ($LocalizedData.UnrecognizedAttribute_F1 -f $type, $ParamNode.LocalName) }
                }
            }

            # TOOD: PICK ONE APPROACH
            Set-Variable -Name "PLASTER_PARAM_$name" -Value $value -Scope Script
            $parameters[$name] = $value
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

        function GenerateModuleManifest([ValidateNotNull()]$NewModuleManifestNode) {
            $moduleVersion = ExpandString $NewModuleManifestNode.moduleVersion
            $rootModule = ExpandString $NewModuleManifestNode.rootModule
            $dstRelPath = ExpandString $NewModuleManifestNode.destination
            $dstPath = Join-Path $DestinationPath $dstRelPath

            # TODO: This generates a file and as such should participate in file
            # conflict resolution. I think we should gen the file here and then
            # use the normal ProcessFile (or function used by ProcessFile) to handle file conflicts.
            if ($PSCmdlet.ShouldProcess($dstPath, $LocalizedData.ShouldProcessGenerateModuleManifest)) {
                New-ModuleManifest -Path $dstPath -ModuleVersion $moduleVersion -RootModule $rootModule
            }
        }

        function ReplaceContent([string]$Path, $Content, [ValidateNotNull()]$ReplaceNode) {
            $pattern = ExpandString $ReplaceNode.pattern
            $replacement = ExpandString $ReplaceNode.replacement

            if ($PSCmdlet.ShouldProcess($Path, ($LocalizedData.ShouldProcessReplaceContent_F2 -f $pattern, $replacement))) {
                if ($null -eq $Content) {
                    $Content = Get-Content $Path -Raw
                }
                $Content -replace $pattern,$replacement
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

                Set-Content -Path $Path -Value $newContent -Encoding $encoding
            }
        }

        function ProcessFile([ValidateNotNull()]$FileNode) {
            $srcRelPath = ExpandString $FileNode.source
            $dstRelPath = ExpandString $FileNode.destination
            $encoding = ExpandString $FileNode.encoding
            $isTemplate = $FileNode.template -eq 'true'

            if (!$encoding) {
                $encoding = "unicode"
            }

            $srcPath = Join-Path $TemplatePath $srcRelPath
            $dstPath = Join-Path $DestinationPath $dstRelPath

            # If the file's parent dir doesn't exist, create it.
            $parentDir = Split-Path $dstPath -Parent
            if (!(Test-Path $parentDir)) {
                if ($PSCmdlet.ShouldProcess($parentDir, $LocalizedData.ShouldProcessCreateDir)) {
                    New-Item -Path $parentDir -ItemType Directory > $null
                }
            }

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
                elseif ($Force -or $PSCmdlet.ShouldContinue("Overwrite $dstPath", 'Plaster file conflict', [ref]$confirmYesToAll, [ref]$confirmNoToAll)) {
                    Copy-Item -LiteralPath $srcPath -Destination $dstPath
                }
            }

            # If file is a template, process the template
            if ($isTemplate) {
                WriteOperationStatus $LocalizedData.OpExpand (ConvertToDestinationRelativePath $dstPath)
                ProcessTemplate $dstPath $encoding
            }

            # Process individual file operations post copy
            $content = $null
            $replaced = $false
            foreach ($node in $FileNode.ChildNodes) {
                if ($node -isnot [System.Xml.XmlElement]) { continue }

                switch ($node.LocalName) {
                    'replace' {
                        $content = ReplaceContent $dstPath $content $node
                        $replaced = $true
                    }
                    default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
                }
            }

            if ($replaced -and $PSCmdlet.ShouldProcess($dstPath, "Modifying file")) {
                WriteOperationStatus $LocalizedData.OpModify (ConvertToDestinationRelativePath $dstPath)
                Set-Content -Path $dstPath -Value $content -Encoding $encoding
            }
        }
    }

    end {
        $manifest = GetManifest

        # Process parameters
        foreach ($node in $manifest.plasterManifest.parameters.ChildNodes) {
            if ($node -isnot [System.Xml.XmlElement]) { continue }
            switch ($node.LocalName) {
                "parameter"  { ProcessParameter $node }
                default { throw ($LocalizedData.UnrecognizedParametersElement_F1 -f $node.LocalName) }
            }
        }

        Write-Verbose "Parameters are:"
#        Write-Verbose "$($parameters | Out-String)"
        Write-Verbose "$(Get-Variable -Name PLASTER_* | Out-String)"

        # Process content
        foreach ($node in $manifest.plasterManifest.content.ChildNodes) {
            if ($node -isnot [System.Xml.XmlElement]) { continue }
            switch ($node.LocalName) {
                'file' {
                    ProcessFile $node
                }
                'newModuleManifest' {
                    GenerateModuleManifest $node
                }
                default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $node.LocalName) }
            }
        }
    }
}

function InitializePredefinedVariables {
    Set-Variable -Name PLASTER_GUID1 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_GUID2 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_GUID3 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_GUID4 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_GUID5 -Value ([Guid]::NewGuid()) -Scope Script

    $now = [DateTime]::Now
    Set-Variable -Name PLASTER_DATE -Value ($now.ToShortDateString()) -Scope Script
    Set-Variable -Name PLASTER_TIME -Value ($now.ToShortTimeString()) -Scope Script
    Set-Variable -Name PLASTER_YEAR -Value ($now.Year) -Scope Script
}

function ExpandString($str) {
    if ($null -eq $str) {
        return ''
    }
    $ExecutionContext.InvokeCommand.ExpandString($str)
}

function ColorForOperation($operation) {
    switch ($operation) {
        $LocalizedData.OpCreate    { 'Green' }
        $LocalizedData.OpExpand    { 'Green' }
        $LocalizedData.OpModify    { 'Green' }
        $LocalizedData.OpIdentical { 'Cyan' }
        $LocalizedData.OpConflict  { 'Red' }
        default { $Host.UI.RawUI.ForegroundColor }
    }
}

function WriteOperationStatus($operation, $message) {
    $maxLen = ($LocalizedData.OpCreate, $LocalizedData.OpIdentical,
               $LocalizedData.OpConflict, $LocalizedData.OpExpand,
               $LocalizedData.OpModify | Measure-Object -Property Length -Maximum).Maximum
    Write-Host ("{0,$maxLen}" -f $operation) -ForegroundColor (ColorForOperation $operation) -NoNewline
    Write-Host " $message"
}

function ConvertToDestinationRelativePath($Path) {
    $fullDestPath = [System.IO.Path]::GetFullPath($DestinationPath)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (!$fullPath.StartsWith($fullDestPath, 'OrdinalIgnoreCase')) {
        throw "$Path must contain $fullDestPath"
    }

    $fullPath.Substring($fullDestPath.Length)
}