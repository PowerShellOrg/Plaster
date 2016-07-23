$ModuleManifestName = 'Plaster.psd1'
$TemplateDir = "$PSScriptRoot\TemplateRootTemp"
$OutDir = "$PSScriptRoot\Out"

Import-Module $PSScriptRoot\..\$ModuleManifestName

function CleanDir {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    $oldDir = Get-Location

    if (!(Test-Path $Path)) {
        New-Item $Path -ItemType Directory
    }

    Set-Location $Path -ErrorAction Stop

    if (!$Path.Contains($PSScriptRoot)) {
        throw "Not deleting dir contents since it isn't under the Tests dir"
    }
    else {
       Remove-Item * -Recurse
    }

    Set-Location $oldDir
}
