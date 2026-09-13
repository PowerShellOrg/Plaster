[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'Command',
    Justification = 'false positive'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'Parameter',
    Justification = 'false positive'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'CommandAst',
    Justification = 'false positive'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter',
    'FakeBoundParams',
    Justification = 'false positive'
)]
[CmdletBinding(DefaultParameterSetName = 'task')]
param(
    [parameter(ParameterSetName = 'task', Position = 0)]
    [ArgumentCompleter( {
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            try {
                Get-PSakeScriptTasks -BuildFile './psakeFile.ps1' -ErrorAction 'Stop' |
                    Where-Object { $_.Name -like "$WordToComplete*" } |
                    Select-Object -ExpandProperty 'Name'
            } catch {
                @()
            }
        })]
    [string[]]$Task = 'default',
    [switch]$Bootstrap,
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$psakeFile = './psakeFile.ps1'

if ($Bootstrap) {
    # Patch TLS protocols for older Windows versions
    [System.Net.ServicePointManager]::SecurityProtocol = (
        [System.Net.ServicePointManager]::SecurityProtocol -bor
        [System.Net.SecurityProtocolType]::Tls12 -bor
        [System.Net.SecurityProtocolType]::Tls13
    )

    Get-PackageProvider -Name 'Nuget' -ForceBootstrap | Out-Null
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'

    # Pin PowerShellGet to v2
    $powerShellGetModule = Get-Module -Name 'PowerShellGet' -ListAvailable |
        Where-Object { $_.Version.Major -eq 2 } |
        Sort-Object -Property 'Version' -Descending |
        Select-Object -First 1

    $powerShellGetModuleParameters = @{
        Name = 'PowerShellGet'
        MinimumVersion = '2.0.0'
        MaximumVersion = '2.99.99'
        Force = $true
    }

    if (-not $powerShellGetModule) {
        Install-Module @powerShellGetModuleParameters -Scope 'CurrentUser' -AllowClobber
    }
    Import-Module @powerShellGetModuleParameters

    # Install PSDepend if missing
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        Install-Module -Name 'PSDepend' -Repository 'PSGallery' -Scope 'CurrentUser' -Force
    }

    # Try-import-first pattern
    $psDependParameters = @{
        Path = $PSScriptRoot
        Recurse = $False
        WarningAction = 'SilentlyContinue'
        Import = $True
        Force = $True
        ErrorAction = 'Stop'
    }

    $psDependTestParameters = $psDependParameters.Clone()
    $null = $psDependTestParameters.Remove('Import')
    $psDependTestParameters['Test'] = $true
    $psDependTestParameters['Quiet'] = $true

    if (-not (Invoke-PSDepend @psDependTestParameters)) {
        $psDependInstallParameters = $psDependParameters.Clone()
        $null = $psDependInstallParameters.Remove('Import')
        Invoke-PSDepend @psDependInstallParameters -Install
    }

    Invoke-PSDepend @psDependParameters
} else {
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        throw 'Missing dependencies. Please run with the "-Bootstrap" flag to install dependencies.'
    }
    Invoke-PSDepend -Path $PSScriptRoot -Recurse $False -WarningAction 'SilentlyContinue' -Import -Force
}

if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -BuildFile $psakeFile |
        Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force
    $invokepsakeSplat = @{
        BuildFile = $psakeFile
        TaskList = $Task
        NoLogo = $true
    }
    if ($Env:GITHUB_ACTIONS) {
        $invokepsakeSplat['OutputFormat'] = 'GitHubActions'
    }
    Invoke-Psake @invokepsakeSplat
    exit ([int](-not $psake.build_success))
}
