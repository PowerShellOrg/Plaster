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
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [string]$Source = 'Plaster'
    )

    # Check if we should log at this level
    $logLevels = @{
        'Error'       = 0
        'Warning'     = 1
        'Information' = 2
        'Verbose'     = 3
        'Debug'       = 4
    }

    $currentLogLevel = $script:LogLevel ?? 'Information'
    $currentLevelValue = $logLevels[$currentLogLevel] ?? 2
    $messageLevelValue = $logLevels[$Level] ?? 2

    if ($messageLevelValue -gt $currentLevelValue) {
        return
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] [$Source] $Message"

    # Handle different log levels appropriately
    switch ($Level) {
        'Error' {
            Write-Error $logMessage -ErrorAction Continue
        }
        'Warning' {
            Write-Warning $logMessage
        }
        'Information' {
            Write-Information $logMessage -InformationAction Continue
        }
        'Verbose' {
            Write-Verbose $logMessage
        }
        'Debug' {
            Write-Debug $logMessage
        }
    }

    # Also write to host for immediate feedback during interactive sessions
    if ($Level -in @('Error', 'Warning') -and $Host.Name -ne 'ServerRemoteHost') {
        $color = switch ($Level) {
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            default { 'White' }
        }
        Write-Host $logMessage -ForegroundColor $color
    }
}
