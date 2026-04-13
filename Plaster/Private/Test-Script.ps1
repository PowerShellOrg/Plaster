function Test-Script {
    [CmdletBinding()]
    param(
        [string]$Script,
        [string]$Location
    )
    if ($null -eq $Script) {
        return @([string]::Empty)
    } elseif ([string]::IsNullOrWhiteSpace($Script)) {
        return $Script
    }

    try {
        $res = @(Invoke-ExpressionImpl $Script)
        [string[]]$res
    } catch {
        throw ($LocalizedData.ExpressionExecError_F2 -f $Location, $_)
    }
}
