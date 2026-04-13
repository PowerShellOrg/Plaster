function Get-ErrorLocationFileAttrVal {
    param(
        [string]$ElementName,
        [string]$AttributeName
    )
    $LocalizedData.ExpressionErrorLocationFile_F2 -f $ElementName, $AttributeName
}
