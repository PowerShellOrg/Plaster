function Resolve-ProcessMessage {
    [CmdletBinding()]
    param(
        [ValidateNotNull()]
        $Node
    )
    $text = Resolve-AttributeValue $Node.InnerText '<message>'
    $noNewLine = $Node.nonewline -eq 'true'

    # Eliminate whitespace before and after the text that just happens to get inserted because you want
    # the text on different lines than the start/end element tags.
    $trimmedText = $text -replace '^[ \t]*\n', '' -replace '\n[ \t]*$', ''

    $condition = $Node.condition
    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        $debugText = $trimmedText -replace '\r|\n', ' '
        $maxLength = [Math]::Min(40, $debugText.Length)
        $PSCmdlet.WriteDebug("Skipping message '$($debugText.Substring(0, $maxLength))', condition evaluated to false.")
        return
    }

    Write-Host $trimmedText -NoNewline:($noNewLine -eq 'true')
}
