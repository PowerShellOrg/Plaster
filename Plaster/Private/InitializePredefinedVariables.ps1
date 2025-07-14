function InitializePredefinedVariables {
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