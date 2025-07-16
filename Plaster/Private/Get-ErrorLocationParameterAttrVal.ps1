function Get-ErrorLocationParameterAttrVal {
    param(
        [string]$ParameterName,
        [string]$AttributeName
    )
    $LocalizedData.ExpressionErrorLocationParameter_F2 -f $ParameterName, $AttributeName
}
