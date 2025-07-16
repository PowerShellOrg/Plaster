function Test-ConditionAttribute {
    [CmdletBinding()]
    param(
        [string]$Expression,
        [string]$Location
    )
    if ($null -eq $Expression) {
        return [string]::Empty
    } elseif ([string]::IsNullOrWhiteSpace($Expression)) {
        return $Expression
    }

    try {
        $res = @(Invoke-ExpressionImpl $Expression)
        [bool]$res[0]
    } catch {
        throw ($LocalizedData.ExpressionInvalidCondition_F3 -f $Expression, $Location, $_)
    }
}
