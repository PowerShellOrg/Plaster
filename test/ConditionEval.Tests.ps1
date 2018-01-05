. $PSScriptRoot\Shared.ps1

Describe 'Condition Attribute Evaluation Tests' {
    Context 'Runspace FileSystem provider working' {
        It 'Determines non-existing file is actually not in destination path' {
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
        <file source='Recurse\foo.txt' destination='foo.txt' condition='Test-Path bar.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            # condition should return false (file doesn't exist) which will not copy over the file foo.txt
            Get-Item $OutDir\foo.txt -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It 'Determines existing file is in destination path' {
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
        <file source='Recurse\foo.txt' destination='foo.txt' condition='Test-Path bar.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
            New-Item $OutDir\bar.txt -ItemType File > $null
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            # condition should return true which will copy over the file foo.txt
            Get-Item $OutDir\foo.txt -ErrorAction SilentlyContinue | Foreach-Object Name | Should -BeExactly foo.txt
        }
    }

    Context 'Runspace commands' {
        It 'Get-Content command is available' {
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
        <file source='Recurse\foo.txt' destination='foo.txt' condition='(Get-Content `$PLASTER_TemplatePath\Recurse\foo.txt -raw) -match "is foo"'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            # condition should return true which will copy over the file foo.txt
            Get-Item $OutDir\foo.txt -ErrorAction SilentlyContinue | Foreach-Object Name | Should -BeExactly foo.txt
        }

        It 'Get-Variable command is available' {
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
        <file source='Recurse\foo.txt' destination='foo.txt' condition='Get-Variable PLASTER_TemplatePath'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            # condition should return true which will copy over the file foo.txt
            Get-Item $OutDir\foo.txt -ErrorAction SilentlyContinue | Foreach-Object Name | Should -BeExactly foo.txt
        }

        It 'Compare-Object command is available' {
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
        <file source='Recurse\foo.txt' destination='foo.txt' condition='Compare-Object -IncludeEqual -ExcludeDifferent @("a","b") @("b","c")'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            # condition should return true which will copy over the file foo.txt
            Get-Item $OutDir\foo.txt -ErrorAction SilentlyContinue | Foreach-Object Name | Should -BeExactly foo.txt
        }
    }
}
