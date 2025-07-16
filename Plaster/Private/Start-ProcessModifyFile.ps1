function Start-ProcessModifyFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateNotNull()]
        $Node
    )
    $path = Resolve-AttributeValue $Node.path (Get-ErrorLocationModifyAttrVal path)

    # We could choose to not check this if the condition eval'd to false
    # but I think it is better to let the template author know they've broken the
    # rules for any of the file directives (not just the ones they're testing/enabled).
    if ([System.IO.Path]::IsPathRooted($path)) {
        throw ($LocalizedData.ErrorPathMustBeRelativePath_F2 -f $path, $Node.LocalName)
    }

    $filePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $path))

    # The file's path must be under the DestinationPath specified by the user.
    Test-PathIsUnderDestinationPath $filePath

    $condition = $Node.condition
    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        $PSCmdlet.WriteDebug("Skipping $($Node.LocalName) of '$filePath', condition evaluated to false.")
        return
    }

    $fileContent = [string]::Empty
    if (Test-Path -LiteralPath $filePath) {
        $fileContent = Get-Content -LiteralPath $filePath -Raw
    }

    # Set a Plaster (non-parameter) variable in this and the constrained runspace.
    Set-PlasterVariable -Name FileContent -Value $fileContent -IsParam $false

    $encoding = $Node.encoding
    if (!$encoding) {
        $encoding = $DefaultEncoding
    }

    # If processing a <modify> directive, write the modified contents to a temp file,
    # then apply the normal file conflict detection/resolution handling.
    $target = $LocalizedData.TempFileTarget_F1 -f $filePath
    if ($PSCmdlet.ShouldProcess($target, $LocalizedData.OpModify)) {
        Write-OperationStatus $LocalizedData.OpModify ($LocalizedData.TempFileOperation_F1 -f (ConvertTo-DestinationRelativePath $filePath))

        $modified = $false

        foreach ($childNode in $Node.ChildNodes) {
            if ($childNode -isnot [System.Xml.XmlElement]) { continue }

            switch ($childNode.LocalName) {
                'replace' {
                    $condition = $childNode.condition
                    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)><$($childNode.LocalName)>'")) {
                        $PSCmdlet.WriteDebug("Skipping $($Node.LocalName) $($childNode.LocalName) of '$filePath', condition evaluated to false.")
                        continue
                    }

                    if ($childNode.original -is [string]) {
                        $original = $childNode.original
                    } else {
                        $original = $childNode.original.InnerText
                    }

                    if ($childNode.original.expand -eq 'true') {
                        $original = Resolve-AttributeValue $original (Get-ErrorLocationModifyAttrVal original)
                    }

                    if ($childNode.substitute -is [string]) {
                        $substitute = $childNode.substitute
                    } else {
                        $substitute = $childNode.substitute.InnerText
                    }

                    if ($childNode.substitute.isFile -eq 'true') {
                        $substitute = Get-PSSnippetFunction $substitute
                    } elseif ($childNode.substitute.expand -eq 'true') {
                        $substitute = Resolve-AttributeValue $substitute (Get-ErrorLocationModifyAttrVal substitute)
                    }

                    # Perform Literal Replacement on FileContent (since it will have regex characters)
                    if ($childNode.substitute.isFile) {
                        $fileContent = $fileContent.Replace($original, $substitute)
                    } else {
                        $fileContent = $fileContent -replace $original, $substitute
                    }

                    # Update the Plaster (non-parameter) variable's value in this and the constrained runspace.
                    Set-PlasterVariable -Name FileContent -Value $fileContent -IsParam $false

                    $modified = $true
                }
                default { throw ($LocalizedData.UnrecognizedContentElement_F1 -f $childNode.LocalName) }
            }
        }

        $tempFile = $null

        try {
            # We could use Copy-FileWithConflictDetection to handle the "identical" (not modified) case
            # but if nothing was changed, I'd prefer not to generate a temp file, copy the unmodified contents
            # into that temp file with hopefully the right encoding and then potentially overwrite the original file
            # (different encoding will make the files look different) with the same contents but different encoding.
            # If the intent of the <modify> was simply to change an existing file's encoding then the directive will
            # need to make a whitespace change to the file.
            if ($modified) {
                $tempFile = [System.IO.Path]::GetTempFileName()
                $PSCmdlet.WriteDebug("Created temp file for modified file - $tempFile")

                Write-ContentWithEncoding -Path $tempFile -Content $PLASTER_FileContent -Encoding $encoding
                Copy-FileWithConflictDetection $tempFile $filePath

                if ($PassThru -and ($Node.openInEditor -eq 'true')) {
                    $InvokePlasterInfo.OpenFiles += $filePath
                }
            } else {
                Write-OperationStatus $LocalizedData.OpIdentical (ConvertTo-DestinationRelativePath $filePath)
            }
        } finally {
            if ($tempFile -and (Test-Path $tempFile)) {
                Remove-Item -LiteralPath $tempFile
                $PSCmdlet.WriteDebug("Removed temp file for modified file - $tempFile")
            }
        }
    }
}
