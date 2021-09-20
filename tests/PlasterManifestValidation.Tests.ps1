BeforeDiscovery {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Module Error Handling Tests' {
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
        Remove-Item $PlasterManifestPath -Confirm:$False -ErrorAction SilentlyContinue
        Remove-Item $outDir -Recurse -Confirm:$False
        Remove-Item $TemplateDir -Recurse -Confirm:$False
    }
    Context 'Empty template dir' {
        It 'Throws on missing plasterManifest.xml' {
            { Invoke-Plaster -TemplatePath 'foo\plasterManifest.xml' -DestinationPath $OutDir -NoLogo } | Should -Throw
        }
    }
    Context 'Invalid Manifest File Tests' {
        It 'Throws on not well-formed XML manifest file' {

            "<a></b>" | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should -Throw
        }
        It 'Throws on missing plasterManifest (root) element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<manifest></manifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should -Throw
        }

        It 'Throws on missing target namespace on (root) element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest>
  <metadata>
    <name>string</name>
    <id>string</id>
    <version>string</version>
    <title>string</title>
    <description>string</description>
    <tags>string</tags>
  </metadata>
  <content/>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo *>$null } | Should -Throw
        }

        It 'Throws on missing metadata element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'Throws on missing metadata id element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <version>0.1.0</version>
        <title>TemplateName</title>
        <description>Plaster template for creating the files for a PowerShell module.</description>
        <tags>Module, ModuleManifest, Build</tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'Throws on missing metadata name element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <version>0.1.0</version>
        <title>TemplateName</title>
        <description>Plaster template for creating the files for a PowerShell module.</description>
        <tags>Module, ModuleManifest, Build</tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'Throws on missing metadata version element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <title>TemplateName</title>
        <description>Plaster template for creating the files for a PowerShell module.</description>
        <tags>Module, ModuleManifest, Build</tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'Throws on missing metadata title element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <version>0.1.0</version>
        <description>Plaster template for creating the files for a PowerShell module.</description>
        <tags>Module, ModuleManifest, Build</tags>
    </metadata>
    <parameters>
    </parameters>
    <content>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'Throws on missing content element' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest version="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <version>0.1.0</version>
        <title>TemplateName</title>
        <description>Plaster template for creating the files for a PowerShell module.</description>
        <tags>Module, ModuleManifest, Build</tags>
    </metadata>
    <parameters>
        <parameter name='ModuleName' type='string' prompt='Enter the name of the module.'/>
        <parameter name='Version' type='string' default='1.0.0' store='true' prompt='Enter the version number for the module.'/>
        <parameter name='CreateRootFoler' type='bool' default='true' prompt='Do you want to create the root folder for the project?'/>
    </parameters>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }
    }


    Context 'Not supported schemaVersion' {
        It 'Throws on schemaVersion greater than latest supported schemaVersion' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="1.9999" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>TemplateName</name>
        <id>774de094-48ca-4772-bda9-1163230c539a</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing schemaVersion not supported.</description>
        <tags></tags>
    </metadata>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }
    }


    Context 'Template cannot write outside of the user-specified DestinationPath' {
        It 'Throws on modify path that is absolute path' {

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.3" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>Testing</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <modify path='$env:LOCALAPPDATA\tasks-should-not-be-here.json' encoding='UTF8'
                condition="$false">
            <replace>
                <original>(?s)^(.*)</original>
                <substitute expand='true'>``$1`r`n// Author: John Doe</substitute>
            </replace>
        </modify>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }

        It 'Throws on newModuleManifest destination that is absolute path' {
            $root = if ($IsWindows) { $env:LOCALAPPDATA } else { '/' }
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
        <newModuleManifest destination='{0}foo-should-not-be-here.psd1'
                           moduleVersion='1.2.3.4'
                           rootModule='foo.psm1'
                           encoding='UTF8-NoBOM'/>
    </content>
</plasterManifest>
"@  -f $root | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }

        It 'Throws on templateFile destination that is absolute path' {

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
        <templateFile source='Recurse\a\foo.txt' destination='${Env:LocalAppData}\PlasterTest-ShouldNotBeHere.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }

        It 'Throws on modify relativePath outside of DestinationPath' {

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
        <modify path='..\tasks-should-not-be-here.json' encoding='UTF8'
                condition="$false">
            <replace>
                <original>(?s)^(.*)</original>
                <substitute expand='true'>``$1`r`n// Author: John Doe</substitute>
            </replace>
        </modify>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }

        It 'Throws on newModuleManifest relativePath outside of DestinationPath' {

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
        <newModuleManifest destination='..\foo-should-not-be-here.psd1'
                           moduleVersion='1.2.3.4'
                           rootModule='foo.psm1'
                           encoding='UTF8-NoBOM'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }

        It 'Throws on templateFile relativePath outside of DestinationPath' {

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
        <templateFile source='Recurse\a\foo.txt' destination='..\foo-should-not-be-here.txt'/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6> $null } | Should -Throw
        }
    }
}
