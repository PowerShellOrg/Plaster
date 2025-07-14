function Write-PlasterLog {
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