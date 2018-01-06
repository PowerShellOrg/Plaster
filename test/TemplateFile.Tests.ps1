. $PSScriptRoot\Shared.ps1

Describe 'TemplateFile Directive Tests' {
    Context 'Invalid template files' {
        It 'It does not crash on an empty template file' {
            CleanDir $TemplateDir
            CleanDir $OutDir

@"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <templateFile source='Recurse\empty.txt' destination='empty.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            Get-Item $OutDir\empty.txt | Foreach-Object Length | Should -BeExactly 0
        }

        It 'It does not crash when prompt evaluates to empty' {
            CleanDir $TemplateDir
            CleanDir $OutDir

@'
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <parameters>
        <parameter name='Directory' type='text' prompt='' />
    </parameters>
    <content>
        <templateFile source='Recurse\empty.txt' destination='empty.txt'/>
    </content>
</plasterManifest>
'@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -Directory foo -NoLogo 6> $null

            Get-Item $OutDir\empty.txt | Foreach-Object Length | Should -BeExactly 0
        }
    }
}
