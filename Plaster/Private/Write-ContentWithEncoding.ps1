function Write-ContentWithEncoding {
    [CmdletBinding()]
    param(
        [string]
        $Path,
        [string[]]
        $Content,
        [string]
        $Encoding
    )

    if ($Encoding -match '-nobom') {
        $Encoding, $dummy = $Encoding -split '-'

        $noBomEncoding = $null
        switch ($Encoding) {
            'utf8' { $noBomEncoding = New-Object System.Text.UTF8Encoding($false) }
        }

        if ($null -eq $Content) {
            $Content = [string]::Empty
        }

        [System.IO.File]::WriteAllLines($Path, $Content, $noBomEncoding)
    } else {
        Set-Content -LiteralPath $Path -Value $Content -Encoding $Encoding
    }
}
