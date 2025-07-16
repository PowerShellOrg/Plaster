function Write-ContentWithEncoding {
    [CmdletBinding()]
    param(
        [string]$path,
        [string[]]$content,
        [string]$encoding
    )

    if ($encoding -match '-nobom') {
        $encoding, $dummy = $encoding -split '-'

        $noBomEncoding = $null
        switch ($encoding) {
            'utf8' { $noBomEncoding = New-Object System.Text.UTF8Encoding($false) }
        }

        if ($null -eq $content) {
            $content = [string]::Empty
        }

        [System.IO.File]::WriteAllLines($path, $content, $noBomEncoding)
    } else {
        Set-Content -LiteralPath $path -Value $content -Encoding $encoding
    }
}
