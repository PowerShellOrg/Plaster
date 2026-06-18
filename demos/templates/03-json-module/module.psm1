# <%= $PLASTER_PARAM_ModuleName %>.psm1
# Author: <%= $PLASTER_PARAM_Author %>

function Get-<%= $PLASTER_PARAM_ModuleName %>Info {
    [CmdletBinding()]
    param()
    [pscustomobject]@{
        Module  = '<%= $PLASTER_PARAM_ModuleName %>'
        Author  = '<%= $PLASTER_PARAM_Author %>'
        License = '<%= $PLASTER_PARAM_License %>'
    }
}

Export-ModuleMember -Function Get-<%= $PLASTER_PARAM_ModuleName %>Info
