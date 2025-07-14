[CmdletBinding(DefaultParameterSetName = 'Task')]
param(
  # Build task(s) to execute
  [parameter(ParameterSetName = 'task', position = 0)]
  [ArgumentCompleter( {
      param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
      $psakeFile = './psakeFile.ps1'
      switch ($Parameter) {
        'Task' {
          if ([string]::IsNullOrEmpty($WordToComplete)) {
            Get-PSakeScriptTasks -BuildFile $psakeFile | Select-Object -ExpandProperty Name
          } else {
            Get-PSakeScriptTasks -BuildFile $psakeFile |
              Where-Object { $_.Name -match $WordToComplete } |
              Select-Object -ExpandProperty Name
          }
        }
        default {
        }
      }
    })]
  [string[]]$Task = 'default',

  # Bootstrap dependencies
  [switch]$Bootstrap,

  # List available build tasks
  [parameter(ParameterSetName = 'Help')]
  [switch]$Help,

  # Optional properties to pass to psake
  [hashtable]$Properties,

  # Optional parameters to pass to psake
  [hashtable]$Parameters
)

$ErrorActionPreference = 'Stop'

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
  PackageManagement\Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
  if ((Test-Path -Path ./requirements.psd1)) {
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
      Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }
    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path .\requirements.psd1 -Install -Import -Force -WarningAction SilentlyContinue
  } else {
    Write-Warning 'No [requirements.psd1] found. Skipping build dependency installation.'
  }
}

# Execute psake task(s)
$psakeFile = './psakeFile.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
  Get-PSakeScriptTasks -BuildFile $psakeFile |
    Format-Table -Property Name, Description, Alias, DependsOn
} else {
  Set-BuildEnvironment -Force
  Invoke-psake -buildFile $psakeFile -taskList $Task -nologo -properties $Properties -parameters $Parameters
  exit ([int](-not $psake.build_success))
}