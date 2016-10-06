. $PSScriptRoot\Shared.ps1

Describe 'Invoke-Plaster Tests' {
    Context 'Parameters' {
        It 'DestinationPath creates directory if it doesn''t exist' {
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
        <file source='Recurse\foo.txt' destination='foo.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            $DestPath = Join-Path $OutDir Foo

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo 6> $null

            Test-Path -LiteralPath $DestPath\foo.txt | Should Be $true
        }
    }
}
