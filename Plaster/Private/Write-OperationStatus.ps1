function Write-OperationStatus {
    [CmdletBinding()]
    param(
        $Operation,
        $Message
    )
    $maxLen = Get-MaxOperationLabelLength
    Write-Host ("{0,$maxLen} " -f $Operation) -ForegroundColor (Get-ColorForOperation $Operation) -NoNewline
    Write-Host $Message
}
