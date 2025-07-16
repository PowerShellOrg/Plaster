function New-FileSystemCopyInfo([string]$srcPath, [string]$dstPath) {
    [PSCustomObject]@{
        SrcFileName = $srcPath
        DstFileName = $dstPath
    }
}
