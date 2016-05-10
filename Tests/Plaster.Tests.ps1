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

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}

Describe 'Module Error Handling Tests' {
    Context 'Empty template dir' {
        It 'Throws on missing plasterManifest.xml' {
            CleanDir $TemplateDir
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir } | Should Throw
        }
    }
    Context 'Invalid Manifest File Tests' {
        It 'Throws on invalid manifest (xml) file' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestInvalidXml.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir 3>$null } | Should Throw
        }
        It 'Throws on missing plasterManifest (root) element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingRoot.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir } | Should Throw
        }
        It 'Throws on missing metadata element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadata.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir 3>$null } | Should Throw
        }
        It 'Throws on missing metadata id element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadataId.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir 3>$null } | Should Throw
        }
        It 'Throws on missing metadata version element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadataVersion.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir 3>$null } | Should Throw
        }
        It 'Throws on missing content element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingContent.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir 3>$null } | Should Throw
        }
    }
}
