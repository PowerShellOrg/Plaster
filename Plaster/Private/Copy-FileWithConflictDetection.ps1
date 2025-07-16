<#
Plaster zen for file handling. All file related operations should use this
method to actually write/overwrite/modify files in the DestinationPath. This
method handles detecting conflicts, gives the user a chance to determine how to
handle conflicts. The user can choose to use the Force parameter to force the
overwriting of existing files at the destination path. File processing
(expanding substitution variable, modifying file contents) should always be done
to a temp file (be sure to always remove temp file when done). That temp file is
what gets passed to this function as the $SrcPath. This allows Plaster to alert
the user when the repeated application of a template will modify any existing
file.

NOTE: Plaster keeps track of which files it has "created" (as opposed to
overwritten) so that any later change to that file doesn't trigger conflict
handling.
#>
function Copy-FileWithConflictDetection {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$SrcPath,
        [string]$DstPath
    )
    # Just double-checking that DstPath parameter is an absolute path otherwise
    # it could fail the check that the DstPath is under the overall DestinationPath.
    if (![System.IO.Path]::IsPathRooted($DstPath)) {
        $DstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DstPath)
    }

    # Check if DstPath file conflicts with an existing SrcPath file.
    $operation = $LocalizedData.OpCreate
    $opMessage = ConvertTo-DestinationRelativePath $DstPath
    if (Test-Path -LiteralPath $DstPath) {
        if (Test-FilesIdentical $SrcPath $DstPath) {
            $operation = $LocalizedData.OpIdentical
        } elseif ($script:templateCreatedFiles.ContainsKey($DstPath)) {
            # Plaster created this file previously during template invocation
            # therefore, there is no conflict.  We're simply updating the file.
            $operation = $LocalizedData.OpUpdate
        } elseif ($Force) {
            $operation = $LocalizedData.OpForce
        } else {
            $operation = $LocalizedData.OpConflict
        }
    }

    # Copy the file to the destination
    if ($PSCmdlet.ShouldProcess($DstPath, $operation)) {
        Write-OperationStatus -Operation $operation -Message $opMessage

        if ($operation -eq $LocalizedData.OpIdentical) {
            # If the files are identical, no need to do anything
            return
        }

        if (
            ($operation -eq $LocalizedData.OpCreate) -or
            ($operation -eq $LocalizedData.OpUpdate)
        ) {
            Copy-Item -LiteralPath $SrcPath -Destination $DstPath
            if ($PassThru) {
                $InvokePlasterInfo.CreatedFiles += $DstPath
            }
            $script:templateCreatedFiles[$DstPath] = $null
        } elseif (
            $Force -or
            $PSCmdlet.ShouldContinue(
                ($LocalizedData.OverwriteFile_F1 -f $DstPath),
                $LocalizedData.FileConflict,
                [ref]$script:fileConflictConfirmYesToAll,
                [ref]$script:fileConflictConfirmNoToAll
            )
        ) {
            $backupFilename = New-BackupFilename $DstPath
            Copy-Item -LiteralPath $DstPath -Destination $backupFilename
            Copy-Item -LiteralPath $SrcPath -Destination $DstPath
            if ($PassThru) {
                $InvokePlasterInfo.UpdatedFiles += $DstPath
            }
            $script:templateCreatedFiles[$DstPath] = $null
        }
    }
}
