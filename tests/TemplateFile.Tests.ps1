BeforeDiscovery {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}

Describe 'TemplateFile Directive Tests' {
    BeforeEach {
        $TemplateDir = "TestDrive:\TemplateRootTemp"
        New-Item -ItemType Directory $TemplateDir | Out-Null
        $OutDir = "TestDrive:\Out"
        New-Item -ItemType Directory $OutDir | Out-Null
        $PlasterManifestPath = "$TemplateDir\plasterManifest.xml"
        Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse
    }
    AfterEach {
        Remove-Item $PlasterManifestPath -Confirm:$False
        Remove-Item $outDir -Recurse -Confirm:$False
        Remove-Item $TemplateDir -Recurse -Confirm:$False
    }
    Context 'Invalid template files' {
        It 'It does not crash on an empty template file' {
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
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null
            Get-Item $OutDir\empty.txt | Foreach-Object Length | Should -BeExactly 0
        }

        It 'It does not crash when prompt evaluates to empty' {
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
            Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -Directory foo -NoLogo 6> $null
            Get-Item $OutDir\empty.txt | Foreach-Object Length | Should -BeExactly 0
        }
    }
}
