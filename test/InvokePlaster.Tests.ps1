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

            Test-Path -LiteralPath $DestPath\foo.txt | Should -Be $true
        }

        It 'Does not process conditional parameters that eval to false' {
            CleanDir $TemplateDir
            CleanDir $OutDir

@'
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="1.1" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <parameters>
        <parameter name='Directory' condition="$false" type='text' prompt='Enter root path' />
    </parameters>
    <content>
        <file condition="$PLASTER_PARAM_Directory -eq $null" source='Recurse\foo.txt' destination='foo.txt'/>
    </content>
</plasterManifest>
'@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            $DestPath = Join-Path $OutDir Foo

            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo 6> $null

            Test-Path -LiteralPath $DestPath\foo.txt | Should -Be $true
        }

        It 'PassThru generates object' {
            CleanDir $TemplateDir
            CleanDir $OutDir

@"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" templateType="Project" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <file source='Recurse\foo.txt' destination='foo.txt' openInEditor='true'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            $DestPath = Join-Path $OutDir Foo

            $res = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo -PassThru 6> $null

            $res.Success | Should -Be $true
            $res.TemplateType | Should -Be 'Project'
            $res.TemplatePath -eq $TemplateDir | Should -Be $true
            $res.DestinationPath -eq $DestPath | Should -Be $true
            @($res.CreatedFiles)[0] | Should -Be "$DestPath\foo.txt"
            $res.UpdatedFiles.Count | Should -Be 0
            $res.MissingModules.Count | Should -Be 0
            @($res.OpenFiles)[0] | Should -Be "$DestPath\foo.txt"
        }

        It 'Throws an error when an invalid manifest path is given' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            {Invoke-Plaster -TemplatePath . -DestinationPath . -NoLogo} | Should -Throw
        }
    }
}
