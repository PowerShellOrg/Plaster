# All Plaster variables should be set via this method so that the ConstrainedRunspace can be
# configured to use the new variable. This method will null out the ConstrainedRunspace so that
# later, when we need to evaluate script in that runspace, it will get recreated first with all
# the latest Plaster variables.
function Set-PlasterVariable {
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

    # Variables created from a <parameter> in the Plaster manifset are prefixed PLASTER_PARAM all others
    # are just PLASTER_.
    $variableName = if ($IsParam) { "PLASTER_PARAM_$Name" } else { "PLASTER_$Name" }

    Set-Variable -Name $variableName -Value $Value -Scope Script -WhatIf:$false

    # If the constrained runspace has been created, it needs to be disposed so that the next string
    # expansion (or condition eval) gets an updated runspace that contains this variable or its new value.
    if ($null -ne $script:ConstrainedRunspace) {
        $script:ConstrainedRunspace.Dispose()
        $script:ConstrainedRunspace = $null
    }
}
