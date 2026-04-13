function Expand-FileSourceSpec {
    [CmdletBinding()]
    param(
        [string]$SourceRelativePath,
        [string]$DestinationRelativePath
    )
    $srcPath = Join-Path $templateAbsolutePath $SourceRelativePath
    $dstPath = Join-Path $destinationAbsolutePath $DestinationRelativePath

    if ($SourceRelativePath.IndexOfAny([char[]]('*', '?')) -lt 0) {
        # No wildcard spec in srcRelPath so return info on single file.
        # Also, if dstRelPath is empty, then use source rel path.
        if (!$DestinationRelativePath) {
            $dstPath = Join-Path $destinationAbsolutePath $SourceRelativePath
        }

        return (New-FileSystemCopyInfo $srcPath $dstPath)
    }

    # Prepare parameter values for call to Get-ChildItem to get list of files
    # based on wildcard spec.
    $gciParams = @{}
    $parent = Split-Path $srcPath -Parent
    $leaf = Split-Path $srcPath -Leaf
    $gciParams['LiteralPath'] = $parent
    $gciParams['File'] = $true

    if ($leaf -eq '**') {
        $gciParams['Recurse'] = $true
    } else {
        if ($leaf.IndexOfAny([char[]]('*', '?')) -ge 0) {
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

    # Generate a FileCopyInfo object for every file expanded by the wildcard spec.
    $files = @(Microsoft.PowerShell.Management\Get-ChildItem @gciParams)
    foreach ($file in $files) {
        $fileSrcPath = $file.FullName
        $relPath = $fileSrcPath.Substring($srcRelRootPathLength)
        $fileDstPath = Join-Path $dstPath $relPath
        New-FileSystemCopyInfo $fileSrcPath $fileDstPath
    }

    # Copy over empty directories - if any.
    $gciParams.Remove('File')
    $gciParams['Directory'] = $true
    $dirs = @(Microsoft.PowerShell.Management\Get-ChildItem @gciParams |
            Where-Object { $_.GetFileSystemInfos().Length -eq 0 })
    foreach ($dir in $dirs) {
        $dirSrcPath = $dir.FullName
        $relPath = $dirSrcPath.Substring($srcRelRootPathLength)
        $dirDstPath = Join-Path $dstPath $relPath
        New-FileSystemCopyInfo $dirSrcPath $dirDstPath
    }
}
