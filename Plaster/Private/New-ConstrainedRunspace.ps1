function New-ConstrainedRunspace {
    [CmdletBinding()]
    param ()
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
    if (!$IsCoreCLR) {
        $iss.ApartmentState = [System.Threading.ApartmentState]::STA
    }
    $iss.LanguageMode = [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage
    $iss.DisableFormatUpdates = $true

    $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'Environment', ([Microsoft.PowerShell.Commands.EnvironmentProvider]), $null
    $iss.Providers.Add($sspe)

    $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'FileSystem', ([Microsoft.PowerShell.Commands.FileSystemProvider]), $null
    $iss.Providers.Add($sspe)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Content', ([Microsoft.PowerShell.Commands.GetContentCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Date', ([Microsoft.PowerShell.Commands.GetDateCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-ChildItem', ([Microsoft.PowerShell.Commands.GetChildItemCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Item', ([Microsoft.PowerShell.Commands.GetItemCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-ItemProperty', ([Microsoft.PowerShell.Commands.GetItemPropertyCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Module', ([Microsoft.PowerShell.Commands.GetModuleCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Variable', ([Microsoft.PowerShell.Commands.GetVariableCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Test-Path', ([Microsoft.PowerShell.Commands.TestPathCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Out-String', ([Microsoft.PowerShell.Commands.OutStringCommand]), $null
    $iss.Commands.Add($ssce)

    $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Compare-Object', ([Microsoft.PowerShell.Commands.CompareObjectCommand]), $null
    $iss.Commands.Add($ssce)

    $scopedItemOptions = [System.Management.Automation.ScopedItemOptions]::AllScope
    $plasterVars = Get-Variable -Name PLASTER_*, PSVersionTable
    if (Test-Path Variable:\IsLinux) {
        $plasterVars += Get-Variable -Name IsLinux
    }
    if (Test-Path Variable:\IsOSX) {
        $plasterVars += Get-Variable -Name IsOSX
    }
    if (Test-Path Variable:\IsMacOS) {
        $plasterVars += Get-Variable -Name IsMacOS
    }
    if (Test-Path Variable:\IsWindows) {
        $plasterVars += Get-Variable -Name IsWindows
    }
    foreach ($var in $plasterVars) {
        $ssve = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry `
            $var.Name, $var.Value, $var.Description, $scopedItemOptions
        $iss.Variables.Add($ssve)
    }

    # Create new runspace with the above defined entries. Then open and set its working dir to $destinationAbsolutePath
    # so all condition attribute expressions can use a relative path to refer to file paths e.g.
    # condition="Test-Path src\${PLASTER_PARAM_ModuleName}.psm1"
    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
    $runspace.Open()
    if ($destinationAbsolutePath) {
        $runspace.SessionStateProxy.Path.SetLocation($destinationAbsolutePath) > $null
    }
    $runspace
}
