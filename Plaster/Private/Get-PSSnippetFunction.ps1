function Get-PSSnippetFunction {
    param(
        [String]$FilePath
    )

    # Test if Path Exists
    if (!(Test-Path $substitute -PathType Leaf)) {
        throw ($LocalizedData.ErrorPathDoesNotExist_F1 -f $FilePath)
    }
    # Load File
    return Get-Content -LiteralPath $substitute -Raw
}
