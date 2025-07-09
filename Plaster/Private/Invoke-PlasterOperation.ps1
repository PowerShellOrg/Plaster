# Enhanced error handling wrapper
function Invoke-PlasterOperation {
    <#
    .SYNOPSIS
    Wraps the execution of a script block with enhanced error handling and
    logging capabilities.

    .DESCRIPTION
    This function wraps the execution of a script block with enhanced error
    handling and logging capabilities.

    .PARAMETER ScriptBlock
    The script block to execute.

    .PARAMETER OperationName
    The name of the operation being performed.

    .PARAMETER PassThru
    If specified, the output of the script block output will be returned.

    .EXAMPLE
    Invoke-PlasterOperation -ScriptBlock { Get-Process } -OperationName 'GetProcesses' -PassThru

    This example executes the `Get-Process` cmdlet within the context of the
    `Invoke-PlasterOperation` function, logging the operation and returning the
    output.

    .NOTES
    This function is designed to be used within the Plaster module to ensure
    consistent logging and error handling across various operations.
    It is not intended for direct use outside of the Plaster context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]
        $ScriptBlock,

        [string]
        $OperationName = 'PlasterOperation',

        [switch]
        $PassThru
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
