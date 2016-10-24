# The Get-<%=$PLASTER_PARAM_TargetResourceName%> function fetches the status of the <%=$PLASTER_PARAM_TargetResourceName%> resource instance specified
# in the parameters for the target machine.
function Get-<%=$PLASTER_PARAM_TargetResourceName%> {
    [OutputType([Hashtable])]
    param (
    )

    # Return a hashtable of name/value pairs representing the target resource instance.
    @{

    }
}

# The Set-<%=$PLASTER_PARAM_TargetResourceName%> function is used to create, delete or configure a <%=$PLASTER_PARAM_TargetResourceName%> resource
# instance for the target machine.
function Set-<%=$PLASTER_PARAM_TargetResourceName%> {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
    )

    # Set the target resource instance based on parameters passed into function.
    if ($PSCmdlet.ShouldProcess("<%=$PLASTER_PARAM_TargetResourceName%>", "Set Resource")) {

    }
}

# The Test-<%=$PLASTER_PARAM_TargetResourceName%> function tests the status of the <%=$PLASTER_PARAM_TargetResourceName%> resource instance specified
# in the parameters for the target machine.
function Test-<%=$PLASTER_PARAM_TargetResourceName%> {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
    )

    [bool]$result = $false

    # Test the status of the target resource instance.  Return either $true or $false.

    $result
}

Export-ModuleMember -Function Get-<%=$PLASTER_PARAM_TargetResourceName%>, Set-<%=$PLASTER_PARAM_TargetResourceName%>, Test-<%=$PLASTER_PARAM_TargetResourceName%>
