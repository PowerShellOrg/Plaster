function Read-PromptForInput {
    [CmdletBinding()]
    param(
        $prompt,
        $default,
        $pattern,
        [switch]$AllowEmpty
    )
    if (!$pattern) {
        $patternMatch = $true
    }

    do {
        $value = Read-Host -Prompt $prompt
        if (!$value -and ($AllowEmpty -or $default)) {
            $value = $default
            $patternMatch = $true
        } elseif ($value -and $pattern) {
            if ($value -match $pattern) {
                $patternMatch = $true
            } else {
                $PSCmdlet.WriteDebug("Value '$value' did not match the pattern '$pattern'")
            }
        }
    } while ((!$value -and !$AllowEmpty) -or !$patternMatch)

    $value
}
