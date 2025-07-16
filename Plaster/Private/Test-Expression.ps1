function Test-Expression([string]$Expression, [string]$Location) {
    if ($null -eq $Expression) {
        return [string]::Empty
    } elseif ([string]::IsNullOrWhiteSpace($Expression)) {
        return $Expression
    }

    try {
        $res = @(Invoke-ExpressionImpl $Expression)
        [string]$res[0]
    } catch {
        throw ($LocalizedData.ExpressionExecError_F2 -f $Location, $_)
    }
}
