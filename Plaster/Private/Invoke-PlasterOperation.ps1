# Enhanced error handling wrapper
function Invoke-PlasterOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [string]$OperationName = 'PlasterOperation',

        [switch]$PassThru
    )

    try {
        Write-PlasterLog -Level Debug -Message "Starting operation: $OperationName"
        $result = & $ScriptBlock
        Write-PlasterLog -Level Debug -Message "Completed operation: $OperationName"

        if ($PassThru) {
            return $result
        }
    } catch {
        $errorMessage = "Operation '$OperationName' failed: $($_.Exception.Message)"
        Write-PlasterLog -Level Error -Message $errorMessage
        throw $_
    }
}