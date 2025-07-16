function Resolve-AttributeValue {
    [CmdletBinding()]
    param(
        [string]$Value,
        [string]$Location
    )

    if ($null -eq $Value) {
        return [string]::Empty
    } elseif ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    try {
        $res = @(Invoke-ExpressionImpl "`"$Value`"")
        [string]$res[0]
    } catch {
        throw ($LocalizedData.InterpolationError_F3 -f $Value.Trim(), $Location, $_)
    }
}
