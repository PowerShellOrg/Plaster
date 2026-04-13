function Write-OperationAdditionalStatus {
    [CmdletBinding()]
    param(
        [string[]]$Message
    )
    $maxLen = Get-MaxOperationLabelLength
    foreach ($msg in $Message) {
        $lines = $msg -split "`n"
        foreach ($line in $lines) {
            Write-Host ("{0,$maxLen} {1}" -f "", $line)
        }
    }
}
