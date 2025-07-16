function Write-OperationStatus {
    [CmdletBinding()]
    param(
        $operation,
        $message
    )
    $maxLen = Get-MaxOperationLabelLength
    Write-Host ("{0,$maxLen} " -f $operation) -ForegroundColor (Get-ColorForOperation $operation) -NoNewline
    Write-Host $message
}
