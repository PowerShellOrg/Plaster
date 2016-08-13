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
            Copy-Item $PSScriptRoot\Manifests\manifestNotWellFormedXml.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should Throw
        }
        It 'Throws on missing plasterManifest (root) element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestMissingRoot.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should Throw
        }
        It 'Throws on missing target namespace on (root) element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestNoTargetNamespace.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should Throw
        }
        It 'Throws on missing metadata element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestMissingMetadata.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing metadata id element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestMissingMetadataId.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing metadata version element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestMissingMetadataVersion.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
        It 'Throws on missing content element' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestMissingContent.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should Throw
        }
    }
    Context 'Not supported schemaVersion' {
        It 'Throws on schemaVersion greater than latest supported schemaVersion' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\manifestNotSupportVersion.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null} | Should Throw
        }
    }

    Context 'Template cannot write outside of the user-specified DestinationPath' {
        It 'Throws on modify path that is absolute path' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\modifyAbsolutePath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
        It 'Throws on newModuleManifest destination that is absolute path' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\newModManifestAbsolutePath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
        It 'Throws on templateFile destination that is absolute path' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\templateFileAbsolutePath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
        It 'Throws on modify relativePath outside of DestinationPath' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\modifyOutsideDestPath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
        It 'Throws on newModuleManifest relativePath outside of DestinationPath' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\newModManOutsideDestPath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
        It 'Throws on templateFile relativePath outside of DestinationPath' {
            CleanDir $TemplateDir
            Copy-Item $PSScriptRoot\Manifests\templateFileOutsideDestPath.xml $TemplateDir\plasterManifest.xml
            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo} | Should Throw
        }
    }
}
