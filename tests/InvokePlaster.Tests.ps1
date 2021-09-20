BeforeDiscovery {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Invoke-Plaster Tests' {
    BeforeEach {
        $TemplateDir = "TestDrive:\TemplateRootTemp"
        New-Item -ItemType Directory $TemplateDir | Out-Null
        $OutDir = "TestDrive:\Out"
        New-Item -ItemType Directory $OutDir | Out-Null
        $PlasterManifestPath = "$TemplateDir\plasterManifest.xml"
        Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
        $DestPath = Join-Path $OutDir Foo
    }
    AfterEach {
        Remove-Item $PlasterManifestPath -Confirm:$False
        Remove-Item $outDir -Recurse -Confirm:$False
        Remove-Item $TemplateDir -Recurse -Confirm:$False
    }
    Context 'Parameters' {
        It 'DestinationPath creates directory if it doesn''t exist' {
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
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo 6> $null

            Test-Path -LiteralPath $DestPath\foo.txt | Should -Be $true
        }

        It 'Does not process conditional parameters that eval to false' {
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
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo 6> $null

            Test-Path -LiteralPath $DestPath\foo.txt | Should -Be $true
        }

        It 'PassThru generates object' {
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
            $res = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo -PassThru 6> $null

            # Snagged from Pester documentation
            function GetFullPath {
                Param(
                    [string] $Path
                )
                $full = $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
                return (Resolve-Path $full).Path
            }

            $res.Success | Should -Be $true
            $res.TemplateType | Should -Be 'Project'
            $res.TemplatePath | Should -Be (GetFullPath -Path $TemplateDir)
            $res.DestinationPath | Should -Be (GetFullPath -Path $DestPath)
            @($res.CreatedFiles)[0] | Should -Be (GetFullPath -Path "$DestPath\foo.txt")
            $res.UpdatedFiles.Count | Should -Be 0
            $res.MissingModules.Count | Should -Be 0
            @($res.OpenFiles)[0] | Should -Be (GetFullPath -Path "$DestPath\foo.txt")
        }

        It 'Text parameter with default value where condition evaluates to false returns default value' {
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
        <parameter name='TestParameter' default="MyValue" condition="$false" type='text' prompt='Enter string value' />
    </parameters>
    <content>
        <file condition="$PLASTER_PARAM_TestParameter -ne $null" source='Recurse\foo.txt' destination='foo.txt'/>
    </content>
</plasterManifest>
'@ | Out-File $PlasterManifestPath -Encoding utf8
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo 6> $null

            Test-Path -LiteralPath $DestPath\foo.txt | Should -Be $true
        }
    }
}
