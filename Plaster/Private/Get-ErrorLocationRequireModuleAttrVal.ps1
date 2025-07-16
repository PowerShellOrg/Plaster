function Get-ErrorLocationRequireModuleAttrVal {
    param(
        [string]$ModuleName,
        [string]$AttributeName
    )
    $LocalizedData.ExpressionErrorLocationRequireModule_F2 -f $ModuleName, $AttributeName
}
