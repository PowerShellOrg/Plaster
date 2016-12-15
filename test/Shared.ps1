$ModuleManifestName  = 'Plaster.psd1'
$ModuleManifestPath  = "$PSScriptRoot\..\src\$ModuleManifestName"
$TemplateDir         = "$PSScriptRoot\TemplateRootTemp"
$OutDir              = "$PSScriptRoot\Out"
$PlasterManifestPath = "$TemplateDir\plasterManifest.xml"

if (!$SuppressImportModule) {
    # -Scope Global is needed when running tests from inside of psake, otherwise
    # the module's functions cannot be found in the Plaster\ namespace
    $plasterModule = Import-Module $ModuleManifestPath -Scope Global -PassThru
}

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
