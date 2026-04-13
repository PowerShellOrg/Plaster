function Initialize-PredefinedVariables {
    <#
    .SYNOPSIS
    Initializes predefined variables used by Plaster.

    .DESCRIPTION
    This function sets up several predefined variables that are used throughout
    the Plaster template processing. It includes variables for the template
    path, destination path, and other relevant information.

    .PARAMETER TemplatePath
    The file system path to the Plaster template directory.

    .PARAMETER DestPath
    The file system path to the destination directory.

    .EXAMPLE
    Initialize-PredefinedVariables -TemplatePath "C:\Templates\MyTemplate" -DestPath "C:\Projects\MyProject"

    This example initializes the predefined variables with the specified
    template and destination paths.
    .NOTES
    This function is typically called at the beginning of the Plaster template
    processing to ensure that all necessary variables are set up before any
    template processing occurs.
    #>
    [CmdletBinding()]
    param(
        [string]
        $TemplatePath,
        [string]
        $DestPath
    )

    # Always set these variables, even if the command has been run with -WhatIf
    $WhatIfPreference = $false

    Set-Variable -Name PLASTER_TemplatePath -Value $TemplatePath.TrimEnd('\', '/') -Scope Script

    $destName = Split-Path -Path $DestPath -Leaf
    Set-Variable -Name PLASTER_DestinationPath -Value $DestPath.TrimEnd('\', '/') -Scope Script
    Set-Variable -Name PLASTER_DestinationName -Value $destName -Scope Script
    Set-Variable -Name PLASTER_DirSepChar      -Value ([System.IO.Path]::DirectorySeparatorChar) -Scope Script
    Set-Variable -Name PLASTER_HostName        -Value $Host.Name -Scope Script
    Set-Variable -Name PLASTER_Version         -Value $MyInvocation.MyCommand.Module.Version -Scope Script

    Set-Variable -Name PLASTER_Guid1 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid2 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid3 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid4 -Value ([Guid]::NewGuid()) -Scope Script
    Set-Variable -Name PLASTER_Guid5 -Value ([Guid]::NewGuid()) -Scope Script

    $now = [DateTime]::Now
    Set-Variable -Name PLASTER_Date -Value ($now.ToShortDateString()) -Scope Script
    Set-Variable -Name PLASTER_Time -Value ($now.ToShortTimeString()) -Scope Script
    Set-Variable -Name PLASTER_Year -Value ($now.Year) -Scope Script
}
