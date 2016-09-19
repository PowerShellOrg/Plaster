. $PSScriptRoot\Shared.ps1

Describe 'File Directive ExpandFileSource Tests' {
    Context 'Recurse\** case' {
        It 'It copies all files, preserving directory structure under the Recurse dir' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            Copy-Item $PSScriptRoot\Manifests\expandFileSourceSpec-all-files.xml $TemplateDir\plasterManifest.xml
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -File -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -File -Name
            Compare-Object $src $dst | Should BeNullOrEmpty
        }
        It 'It copies empty directories' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            Copy-Item $PSScriptRoot\Manifests\expandFileSourceSpec-all-files.xml $TemplateDir\plasterManifest.xml
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -Directory -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -Directory -Name
            Compare-Object $src $dst | Should BeNullOrEmpty
        }
    }
    Context 'Recurse\*.txt case' {
        It 'It copies only empty.txt, foo.txt under the Recurse dir' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            Copy-Item $PSScriptRoot\Manifests\expandFileSourceSpec-txt-file.xml $TemplateDir\plasterManifest.xml
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -File -Filter *.txt -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -File -Filter *.txt -Name
            $dst | Should Be "empty.txt", "foo.txt"
        }
    }
    Context 'Recurse\**\*.txt case' {
        It 'It copies all *.txt files, preserving directory structure under the Recurse dir' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            Copy-Item $PSScriptRoot\Manifests\expandFileSourceSpec-all-txt-files.xml $TemplateDir\plasterManifest.xml
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -File -Filter *.txt -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -File -Filter *.txt -Name
            Compare-Object $src $dst | Should BeNullOrEmpty
        }
    }
}
