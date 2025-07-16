function New-FileSystemCopyInfo {
    [CmdletBinding()]
    param(
        [string]$srcPath,
        [string]$dstPath
    )
    [PSCustomObject]@{
        SrcFileName = $srcPath
        DstFileName = $dstPath
    }
}
