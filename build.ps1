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
            }
            catch {
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
        Name           = 'PowerShellGet'
        MinimumVersion = '2.0.0'
        MaximumVersion = '2.99.99'
        Force          = $true
    }

    if (-not $powerShellGetModule) {
        Install-Module @powerShellGetModuleParameters -Scope 'CurrentUser' -AllowClobber
    }
    Import-Module @powerShellGetModuleParameters

    # Register internal repository (idempotent)
    $repositoryName = 'internal-nuget-repo'
    if (-not (Get-PSRepository -Name $repositoryName -ErrorAction 'SilentlyContinue')) {
        $repositoryUrl = "https://nuget.example.com/api/v2/$repositoryName"
        $registerPSRepositorySplat = @{
            Name                      = $repositoryName
            SourceLocation            = $repositoryUrl
            PublishLocation           = $repositoryUrl
            ScriptSourceLocation      = $repositoryUrl
            InstallationPolicy        = 'Trusted'
            PackageManagementProvider = 'NuGet'
        }
        Register-PSRepository @registerPSRepositorySplat
    }

    # Install PSDepend if missing
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        Install-Module -Name 'PSDepend' -Repository 'PSGallery' -Scope 'CurrentUser' -Force
    }

    # Try-import-first pattern
    $psDependParameters = @{
        Path          = $PSScriptRoot
        Recurse       = $False
        WarningAction = 'SilentlyContinue'
        Import        = $True
        Force         = $True
        ErrorAction   = 'Stop'
    }

    $importSucceeded = $false
    try {
        Invoke-PSDepend @psDependParameters
        $importSucceeded = $true
        Write-Verbose 'Successfully imported existing modules.' -Verbose
    }
    catch {
        Write-Verbose "Could not import all required modules: $_" -Verbose
        Write-Verbose 'Attempting to install missing or outdated dependencies...' -Verbose
    }

    if (-not $importSucceeded) {
        try {
            Invoke-PSDepend @psDependParameters -Install
        }
        catch {
            Write-Error "Failed to install and import required dependencies: $_"
            Write-Error 'This may be due to locked module files. Please restart the build environment or clear module locks.'
            if ($_.Exception.InnerException) {
                Write-Error "Inner exception: $($_.Exception.InnerException.Message)"
            }
            throw
        }
    }
}
else {
    if (-not (Get-Module -Name 'PSDepend' -ListAvailable)) {
        throw 'Missing dependencies. Please run with the "-Bootstrap" flag to install dependencies.'
    }
    Invoke-PSDepend -Path $PSScriptRoot -Recurse $False -WarningAction 'SilentlyContinue' -Import -Force
}

if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile |
        Format-Table -Property Name, Description, Alias, DependsOn
}
else {
    Set-BuildEnvironment -Force
    Invoke-psake -buildFile $psakeFile -taskList $Task -nologo
    exit ([int](-not $psake.build_success))
}
