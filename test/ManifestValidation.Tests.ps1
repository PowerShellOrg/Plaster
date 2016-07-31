. $PSScriptRoot\Shared.ps1

Describe 'Module Error Handling Tests' {
    Context 'Empty template dir' {
        It 'Throws on missing plasterManifest.xml' {
            CleanDir $TemplateDir
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo } | Should Throw
        }
    }
    Context 'Invalid Manifest File Tests' {
        It 'Throws on not well-formed XML manifest file' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestNotWellFormedXml.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing plasterManifest (root) element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingRoot.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo } | Should Throw
        }
        It 'Throws on missing target namespace on (root) element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestNoTargetNamespace.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo } | Should Throw
        }
        It 'Throws on missing metadata element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadata.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing metadata id element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadataId.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing metadata version element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingMetadataVersion.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing content element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\plasterManifestMissingContent.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
    }
}
