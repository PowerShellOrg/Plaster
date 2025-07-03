function Invoke-ExpressionImpl {
    [CmdletBinding()]
    param (
        [string]$Expression
    )
    try {
        $powershell = [PowerShell]::Create()

        if ($null -eq $constrainedRunspace) {
            $constrainedRunspace = NewConstrainedRunspace
        }
        $powershell.Runspace = $constrainedRunspace

        try {
            $powershell.AddScript($Expression) > $null
            $res = $powershell.Invoke()

            # Enhanced logging for JSON expressions
            if ($Expression -match '\$\{.*\}' -and $manifestType -eq 'JSON') {
                Write-PlasterLog -Level Debug -Message "JSON expression evaluated: $Expression -> $res"
            }

            return $res
        }
        catch {
            throw ($LocalizedData.ExpressionInvalid_F2 -f $Expression,$_)
        }

        if ($powershell.Streams.Error.Count -gt 0) {
            $err = $powershell.Streams.Error[0]
            throw ($LocalizedData.ExpressionNonTermErrors_F2 -f $Expression,$err)
        }
    }
    finally {
        if ($powershell) {
            $powershell.Dispose()
        }
    }
}
