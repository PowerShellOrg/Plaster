function Write-PlasterLog {
    <#
    .SYNOPSIS
    Logs messages with different severity levels for Plaster operations.

    .DESCRIPTION
    This function logs messages with different severity levels for Plaster
    operations.

    .PARAMETER Level
    The severity level of the log message. Possible values are 'Error',
    'Warning', 'Information', 'Verbose', and 'Debug'. The log message will be
    formatted with a timestamp and the source of the log.

    .PARAMETER Message
    The message to log.

    .PARAMETER Source
    The source of the log message.

    .EXAMPLE
    Write-PlasterLog -Level 'Information' -Message 'This is an informational message.'

    This example logs an informational message with the specified level and
    source.
    .NOTES
    This function is designed to be used within the Plaster module to ensure
    consistent logging across various operations.
    It is not intended for direct use outside of the Plaster context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Source = 'Plaster'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] [$Source] $Message"

    switch ($Level) {
        'Error' { Write-Error $logMessage }
        'Warning' { Write-Warning $logMessage }
        'Information' { Write-Information $logMessage }
        'Verbose' { Write-Verbose $logMessage }
        'Debug' { Write-Debug $logMessage }
    }
}
