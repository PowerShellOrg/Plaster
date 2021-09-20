BeforeDiscovery {
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'RequireModule Directive Tests' {
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
    Context 'Finds module' {
        It 'It finds module with no version number' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }

        It 'It finds module based on minimumVersion' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" minimumVersion="1.0.0.0" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }

        It 'It finds module based on maximumVersion' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" maximumVersion="9999.9.9.9" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }

        It 'It finds module based on minimumVersion and maximumVersion' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" minimumVersion="1.0.0.0" maximumVersion="9999.9.9.9" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }

        It 'It finds module based on requiredVersion' {
            # Grab the 0th item since there could be many
            $version = (Get-Module -ListAvailable Microsoft.PowerShell.Management)[0].Version.ToString()

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" requiredVersion="$version" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }
    }


    Context 'Should not find module that doesn not exist or is not the specified version' {
        It 'Determines non-existing module is missing with no version information' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="XYZZY-ABC-JPGR-JBJL" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Missing'
        }

        It 'Determines minimum version of module is missing' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
            <requireModule name="Microsoft.PowerShell.Management" minimumVersion="9999.9.9.9" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Missing'
        }

        It 'Determines maximum version of module is missing' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
            <requireModule name="Microsoft.PowerShell.Management" maximumVersion="1.0.0.0" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Missing'
        }

        It 'Determines required version of module is missing' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
            <requireModule name="Microsoft.PowerShell.Management" requiredVersion="0.0.0.0" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Missing'
        }
    }


    Context 'Test condition attribute' {
        It 'True condition evaluates requireModule directive' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" condition="`$true" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
        }

        It 'False condition does not evaluate requireModule directive' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" condition="`$false" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            "$output" | Should -Match "^Destination path:"
            $output.Count | Should -Be 1
        }
    }


    Context 'Test message attribute' {
        It 'Outputs message when module not found' {
            $message = "BUMMER DUDE"

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="XYZZY-ABC-JPGR-JBJL" message="$message" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Missing'
            $output[3] | Should -Match $message
        }

        It 'Does not output message when module is found' {
            $message = "BUMMER DUDE"

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Microsoft.PowerShell.Management" message="$message" />
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $OFS = ''
            $output = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 6>&1
            $output[1] | Should -Match '^\s*Verify'
            $output[1] -notmatch $message | Should -Be $true
        }
    }

    Context 'Invalid attribute combinations' {
        It 'It fails on combined requiredVersion with minimumVersion' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Pester" minimumVersion="1.0.0" requiredVersion="1.2.3"/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }

        It 'It fails on combined requiredVersion with maximumVersion' {
            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>0.2.0</version>
        <name>TemplateName</name>
        <title>Testing</title>
        <description>Manifest file for testing.</description>
        <tags></tags>
    </metadata>
    <content>
        <requireModule name="Pester" maximumVersion="1.0.0" requiredVersion="1.2.3"/>
    </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            { Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $OutDir -NoLogo 3>$null } | Should -Throw
        }
    }
}
