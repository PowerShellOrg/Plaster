#Requires -Modules psake
[cmdletbinding(DefaultParameterSetName = 'Task')]
param(
  # Build task(s) to execute
  [parameter(ParameterSetName = 'task', position = 0)]
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

# Execute psake task(s)
$psakeFile = "$PSScriptRoot\psakeFile.ps1"
if ($PSCmdlet.ParameterSetName -eq 'Help') {
  Get-PSakeScriptTasks -buildFile $psakeFile |
  Format-Table -Property Name, Description, Alias, DependsOn
} else {
  Set-BuildEnvironment -Force
  $parameters = @{}
  if ($PSGalleryApiKey) {
    $parameters['galleryApiKey'] = $PSGalleryApiKey
  }
  $psake_splat = @{
    buildFile  = $psakeFile
    taskList   = $Task
    nologo     = $True
    properties = $Properties
    parameters = $Parameters
  }
  Invoke-PSake @psake_splat
  exit ([int](-not $psake.build_success))
}