function Set-PlasterVariable {
    <#
    .SYNOPSIS
    Sets a Plaster variable in the script scope and updates the
    ConstrainedRunspace if it exists.

    .DESCRIPTION
    This function sets a variable in the script scope and updates the
    ConstrainedRunspace if it exists. It is used to manage Plaster variables,
    which can be parameters or other types of variables.

    .PARAMETER Name
    The name of the variable to set.

    .PARAMETER Value
    The value to assign to the variable.

    .PARAMETER IsParam
    Indicates if the variable is a parameter.
    If true, the variable is treated as a Plaster parameter and prefixed with
    "PLASTER_PARAM_".

    .EXAMPLE
    Set-PlasterVariable -Name "MyVariable" -Value "MyValue" -IsParam $true

    Sets a Plaster parameter variable named "PLASTER_PARAM_MyVariable" with the
    value "MyValue".
    .NOTES
    All Plaster variables should be set via this method so that the
    ConstrainedRunspace can be configured to use the new variable. This method
    will null out the ConstrainedRunspace so that later, when we need to
    evaluate script in that runspace, it will get recreated first with all
    the latest Plaster variables.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Value,

        [Parameter()]
        [bool]
        $IsParam = $true
    )

    # Variables created from a <parameter> in the Plaster manifest are prefixed
    # PLASTER_PARAM all others are just PLASTER_.
    $variableName = if ($IsParam) { "PLASTER_PARAM_$Name" } else { "PLASTER_$Name" }

    Set-Variable -Name $variableName -Value $Value -Scope Script -WhatIf:$false

    # If the constrained runspace has been created, it needs to be disposed so that the next string
    # expansion (or condition eval) gets an updated runspace that contains this variable or its new value.
    if ($null -ne $script:ConstrainedRunspace) {
        $script:ConstrainedRunspace.Dispose()
        $script:ConstrainedRunspace = $null
    }
}
