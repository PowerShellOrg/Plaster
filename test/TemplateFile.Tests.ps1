. $PSScriptRoot\Shared.ps1

Describe 'TemplateFile Directive Tests' {
    Context 'Invalid template files' {
        It 'It does not crash on an empty template file' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            Copy-Item $PSScriptRoot\Manifests\templateFileEmpty.xml $TemplateDir\plasterManifest.xml
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            Get-Item $OutDir\empty.txt | Foreach-Object Length | Should BeExactly 0
        }
    }
}