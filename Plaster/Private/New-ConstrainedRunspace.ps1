function New-ConstrainedRunspace {
    [CmdletBinding()]
    param ()
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
    if (!$IsCoreCLR) {
        $iss.ApartmentState = [System.Threading.ApartmentState]::STA
    }
    $iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage
    $iss.DisableFormatUpdates = $true

    # Add providers
    $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'Environment', ([Microsoft.PowerShell.Commands.EnvironmentProvider]), $null
    $iss.Providers.Add($sspe)

    $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'FileSystem', ([Microsoft.PowerShell.Commands.FileSystemProvider]), $null
    $iss.Providers.Add($sspe)

    # Add cmdlets with enhanced set for JSON processing
    $cmdlets = @(
        'Get-Content', 'Get-Date', 'Get-ChildItem', 'Get-Item', 'Get-ItemProperty',
        'Get-Module', 'Get-Variable', 'Test-Path', 'Out-String', 'Compare-Object',
        'ConvertFrom-Json', 'ConvertTo-Json'  # JSON support
    )

    foreach ($cmdletName in $cmdlets) {
        #$cmdletType = [Microsoft.PowerShell.Commands.GetContentCommand].Assembly.GetType("Microsoft.PowerShell.Commands.$($cmdletName -replace '-')Command")
        $cmdletType = "Microsoft.PowerShell.Commands.$($cmdletName -replace '-')Command" -as [Type]
        if ($cmdletType) {
            $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry $cmdletName, $cmdletType, $null
            $iss.Commands.Add($ssce)
        }
    }

    # Add enhanced variable set including JSON manifest type
    $scopedItemOptions = [System.Management.Automation.ScopedItemOptions]::AllScope
    $plasterVars = Get-Variable -Name PLASTER_*, PSVersionTable

    # Add platform detection variables
    if (Test-Path Variable:\IsLinux) { $plasterVars += Get-Variable -Name IsLinux }
    if (Test-Path Variable:\IsOSX) { $plasterVars += Get-Variable -Name IsOSX }
    if (Test-Path Variable:\IsMacOS) { $plasterVars += Get-Variable -Name IsMacOS }
    if (Test-Path Variable:\IsWindows) { $plasterVars += Get-Variable -Name IsWindows }

    # Add manifest type variable (new for 2.0)
    $manifestTypeVar = New-Object System.Management.Automation.PSVariable 'PLASTER_ManifestType', $manifestType, 'None'
    $plasterVars += $manifestTypeVar

    foreach ($var in $plasterVars) {
        $ssve = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry `
            $var.Name, $var.Value, $var.Description, $scopedItemOptions
        $iss.Variables.Add($ssve)
    }

    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
    $runspace.Open()
    if ($destinationAbsolutePath) {
        $runspace.SessionStateProxy.Path.SetLocation($destinationAbsolutePath) > $null
    }

    Write-PlasterLog -Level Debug -Message "Created enhanced constrained runspace with $manifestType support"
    return $runspace
}
