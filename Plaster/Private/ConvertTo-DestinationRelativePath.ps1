function ConvertTo-DestinationRelativePath {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    $fullDestPath = $DestinationPath
    if (![System.IO.Path]::IsPathRooted($fullDestPath)) {
        $fullDestPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
    }

    $fullPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
    if (!$fullPath.StartsWith($fullDestPath, 'OrdinalIgnoreCase')) {
        throw ($LocalizedData.ErrorPathMustBeUnderDestPath_F2 -f $fullPath, $fullDestPath)
    }

    $fullPath.Substring($fullDestPath.Length).TrimStart('\', '/')
}
