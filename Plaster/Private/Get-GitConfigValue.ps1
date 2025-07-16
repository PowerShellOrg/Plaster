function Get-GitConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$name
    )
    # Very simplistic git config lookup
    # Won't work with namespace, just use final element, e.g. 'name' instead of 'user.name'

    # The $Home dir may not be reachable e.g. if on network share and/or script not running as admin.
    # See issue https://github.com/PowerShell/Plaster/issues/92
    if (!(Test-Path -LiteralPath $Home)) {
        return
    }

    $gitConfigPath = Join-Path $Home '.gitconfig'
    $PSCmdlet.WriteDebug("Looking for '$name' value in Git config: $gitConfigPath")

    if (Test-Path -LiteralPath $gitConfigPath) {
        $matches = Select-String -LiteralPath $gitConfigPath -Pattern "\s+$name\s+=\s+(.+)$"
        if (@($matches).Count -gt 0) {
            $matches.Matches.Groups[1].Value
        }
    }
}
