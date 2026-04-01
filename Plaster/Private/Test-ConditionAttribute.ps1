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
        $expressionToEvaluate = $Expression

        if ($manifestType -eq 'JSON') {
            $expressionToEvaluate = $expressionToEvaluate -replace '\$\{(?!PLASTER_)([A-Za-z][A-Za-z0-9_]*)\}', '${PLASTER_PARAM_$1}'
        }

        $res = @(Invoke-ExpressionImpl $expressionToEvaluate)
        [bool]$res[0]
    } catch {
        throw ($LocalizedData.ExpressionInvalidCondition_F3 -f $Expression, $Location, $_)
    }
}
