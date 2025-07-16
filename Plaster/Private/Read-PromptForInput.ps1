function Read-PromptForInput {
    [CmdletBinding()]
    param(
        $prompt,
        $default,
        $pattern
    )
    if (!$pattern) {
        $patternMatch = $true
    }

    do {
        $value = Read-Host -Prompt $prompt
        if (!$value -and $default) {
            $value = $default
            $patternMatch = $true
        } elseif ($value -and $pattern) {
            if ($value -match $pattern) {
                $patternMatch = $true
            } else {
                $PSCmdlet.WriteDebug("Value '$value' did not match the pattern '$pattern'")
            }
        }
    } while (!$value -or !$patternMatch)

    $value
}
