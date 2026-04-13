function Test-PlasterCondition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Condition,

        [Parameter()]
        [string]$ParameterName,

        [Parameter()]
        [string]$Context = 'condition'
    )

    try {
        # Basic syntax validation - ensure it's valid PowerShell
        $tokens = $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput($Condition, [ref]$tokens, [ref]$errors)

        if ($errors.Count -gt 0) {
            $errorMsg = if ($ParameterName) {
                "Invalid condition in parameter '$ParameterName': $($errors[0].Message)"
            } else {
                "Invalid condition in ${Context}: $($errors[0].Message)"
            }
            throw $errorMsg
        }

        Write-PlasterLog -Level Debug -Message "Condition validation passed: $Condition"
        return $true
    } catch {
        Write-PlasterLog -Level Error -Message "Condition validation failed: $($_.Exception.Message)"
        throw $_
    }
}
