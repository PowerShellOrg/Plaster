function Invoke-ExpressionImpl {
    [CmdletBinding()]
    param (
        [string]$Expression
    )
    try {
        $powershell = [PowerShell]::Create()

        if ($null -eq $script:constrainedRunspace) {
            $script:constrainedRunspace = New-ConstrainedRunspace
        }
        $powershell.Runspace = $script:constrainedRunspace

        try {
            $powershell.AddScript($Expression) > $null
            $res = $powershell.Invoke()
            $res
        } catch {
            throw ($LocalizedData.ExpressionInvalid_F2 -f $Expression, $_)
        }

        # Check for non-terminating errors.
        if ($powershell.Streams.Error.Count -gt 0) {
            $err = $powershell.Streams.Error[0]
            throw ($LocalizedData.ExpressionNonTermErrors_F2 -f $Expression, $err)
        }
    } finally {
        if ($powershell) {
            $powershell.Dispose()
        }
    }
}
