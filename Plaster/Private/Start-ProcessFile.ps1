# Processes both the <file> and <templateFile> directives.
function Start-ProcessFile {
    <#
    .SYNOPSIS
    Processes the <file> and <templateFile> directives in a Plaster template.

    .DESCRIPTION
    This function processes the <file> and <templateFile> directives in a
    Plaster template.
    It resolves the source and destination paths, checks conditions, expands
    file source specifications,

    .PARAMETER Node
    The XML node representing the <file> or <templateFile> directive.

    .EXAMPLE
    Start-ProcessFile -Node $fileNode

    Processes the specified file node, resolving paths and handling conditions.
    .NOTES
    This function is part of the Plaster module and is used internally to handle
    file processing in templates.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateNotNull()]
        $Node
    )
    $resolveAttributeValueSplat = @{
        Value = $Node.source
        Location = (Get-ErrorLocationFileAttrVal $Node.localName source)
    }
    $srcRelPath = Resolve-AttributeValue @resolveAttributeValueSplat

    $resolveAttributeValueSplat = @{
        Value = $Node.destination
        Location = (Get-ErrorLocationFileAttrVal $Node.localName destination)
    }
    $dstRelPath = Resolve-AttributeValue @resolveAttributeValueSplat

    $condition = $Node.condition
    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        $PSCmdlet.WriteDebug("Skipping $($Node.localName) '$srcRelPath' -> '$dstRelPath', condition evaluated to false.")
        return
    }

    # Only validate paths for conditions that evaluate to true.
    # The path may not be valid if it evaluates to false depending
    # on whether or not conditional parameters are used in the template.
    if ([System.IO.Path]::IsPathRooted($srcRelPath)) {
        throw ($LocalizedData.ErrorPathMustBeRelativePath_F2 -f $srcRelPath, $Node.LocalName)
    }

    if ([System.IO.Path]::IsPathRooted($dstRelPath)) {
        throw ($LocalizedData.ErrorPathMustBeRelativePath_F2 -f $dstRelPath, $Node.LocalName)
    }

    # Check if node is the specialized, <templateFile> node.
    # Only <templateFile> nodes expand templates and use the encoding attribute.
    $isTemplateFile = $Node.localName -eq 'templateFile'
    if ($isTemplateFile) {
        $encoding = $Node.encoding
        if (!$encoding) {
            $encoding = $DefaultEncoding
        }
    }

    # Check if source specifies a wildcard and if so, expand the wildcard
    # and then process each file system object (file or empty directory).
    $expandFileSourceSpecSplat = @{
        SourceRelativePath = $srcRelPath
        DestinationRelativePath = $dstRelPath
    }
    $fileSystemCopyInfoObjs = Expand-FileSourceSpec @expandFileSourceSpecSplat
    foreach ($fileSystemCopyInfo in $fileSystemCopyInfoObjs) {
        $srcPath = $fileSystemCopyInfo.SrcFileName
        $dstPath = $fileSystemCopyInfo.DstFileName

        # The file's destination path must be under the DestinationPath specified by the user.
        Test-PathIsUnderDestinationPath $dstPath

        # Check to see if we're copying an empty dir
        if (Test-Path -LiteralPath $srcPath -PathType Container) {
            if (!(Test-Path -LiteralPath $dstPath)) {
                if ($PSCmdlet.ShouldProcess($parentDir, $LocalizedData.ShouldProcessCreateDir)) {
                    Write-OperationStatus $LocalizedData.OpCreate `
                    ($dstRelPath.TrimEnd(([char]'\'), ([char]'/')) + [System.IO.Path]::DirectorySeparatorChar)
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
            $target = $LocalizedData.TempFileTarget_F1 -f (ConvertTo-DestinationRelativePath $dstPath)
            if ($isTemplateFile -and $PSCmdlet.ShouldProcess($target, $LocalizedData.ShouldProcessExpandTemplate)) {
                $content = Get-Content -LiteralPath $srcPath -Raw

                # Eval script expression delimiters
                if ($content -and ($content.Count -gt 0)) {
                    $newContent = [regex]::Replace($content, '(<%=)(.*?)(%>)', {
                            param($match)
                            $expr = $match.groups[2].value
                            $res = Test-Expression $expr "templateFile '$srcRelPath'"
                            $PSCmdlet.WriteDebug("Replacing '$expr' with '$res' in contents of template file '$srcPath'")
                            $res
                        }, @('IgnoreCase'))

                    # Eval script block delimiters
                    $newContent = [regex]::Replace($newContent, '(^<%)(.*?)(^%>)', {
                            param($match)
                            $expr = $match.groups[2].value
                            $res = Test-Script  $expr "templateFile '$srcRelPath'"
                            $res = $res -join [System.Environment]::NewLine
                            $PSCmdlet.WriteDebug("Replacing '$expr' with '$res' in contents of template file '$srcPath'")
                            $res
                        }, @('IgnoreCase', 'SingleLine', 'MultiLine'))

                    $srcPath = $tempFile = [System.IO.Path]::GetTempFileName()
                    $PSCmdlet.WriteDebug("Created temp file for expanded templateFile - $tempFile")

                    Write-ContentWithEncoding -Path $tempFile -Content $newContent -Encoding $encoding
                } else {
                    $PSCmdlet.WriteDebug("Skipping template file expansion for $($Node.localName) '$srcPath', file is empty.")
                }
            }

            Copy-FileWithConflictDetection $srcPath $dstPath

            if ($PassThru -and ($Node.openInEditor -eq 'true')) {
                $InvokePlasterInfo.OpenFiles += $dstPath
            }
        } finally {
            if ($tempFile -and (Test-Path $tempFile)) {
                Remove-Item -LiteralPath $tempFile
                $PSCmdlet.WriteDebug("Removed temp file for expanded templateFile - $tempFile")
            }
        }
    }
}
