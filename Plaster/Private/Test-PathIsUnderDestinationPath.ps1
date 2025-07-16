function Test-PathIsUnderDestinationPath() {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $FullPath
    )
    if (![System.IO.Path]::IsPathRooted($FullPath)) {
        $PSCmdlet.WriteDebug("The FullPath parameter '$FullPath' must be an absolute path.")
    }

    $fullDestPath = $DestinationPath
    if (![System.IO.Path]::IsPathRooted($fullDestPath)) {
        $fullDestPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    }

    if (!$FullPath.StartsWith($fullDestPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw ($LocalizedData.ErrorPathMustBeUnderDestPath_F2 -f $FullPath, $fullDestPath)
    }
}
