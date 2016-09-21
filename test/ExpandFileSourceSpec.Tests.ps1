. $PSScriptRoot\Shared.ps1

Describe 'File Directive ExpandFileSource Tests' {
    Context 'Recurse\** case' {
        It 'It copies all files, preserving directory structure under the Recurse dir' {
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
        <file source='Recurse\**' destination='RecurseOut'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -File -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -File -Name
            Compare-Object $src $dst | Should BeNullOrEmpty
        }

        It 'It copies empty directories' {
            CleanDir $TemplateDir
            CleanDir $OutDir

@"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <version>0.2.0</version>
        <tags></tags>
    </metadata>
    <content>
        <file source='Recurse\**' destination='RecurseOut'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

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

@"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <version>0.2.0</version>
        <tags></tags>
    </metadata>
    <content>
        <file source='Recurse\*.txt' destination='RecurseOut'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

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

@"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>997a137c-b867-44fd-be5f-a62d3a010a85</id>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <version>0.2.0</version>
        <tags></tags>
    </metadata>
    <content>
        <file source='Recurse\**\*.txt' destination='RecurseOut'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null

            $src = Get-ChildItem $PSScriptRoot\Recurse -Recurse -File -Filter *.txt -Name
            $dst = Get-ChildItem $OutDir\RecurseOut -Recurse -File -Filter *.txt -Name
            Compare-Object $src $dst | Should BeNullOrEmpty
        }
    }
}
