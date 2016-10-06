# This builds this module by invoking the build.psake.ps1 script

if ($null -eq (Get-Module -Name PSake -ListAvailable)) {
    throw "You need to install PSake before continuing. Install with 'Install-Module PSake -Scope CurrentUser'."
}

Import-Module Psake
Invoke-PSake $PSScriptRoot\build.psake.ps1 -taskList Build
