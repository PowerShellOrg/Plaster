. $PSScriptRoot\Shared.ps1

$plasterModule = Get-Module Plaster
$SchemaVersion = $plasterModule.Invoke({$LatestSupportedSchemaVersion})

Describe 'Test-PlasterManifest Command Tests' {
    Context 'Verifies manifest schema version correctly' {
        It 'Errors on manifest major version greater than supported' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="9999.0" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            $TestErr.Exception.Message -match "requires a newer version of Plaster" | Should Be $true
        }

        It 'Errors on manifest major version equal but minor version greater than supported' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor + 1)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            $TestErr.Exception.Message -match "requires a newer version of Plaster" | Should Be $true
        }

        It 'Works on manifest major version equal to latest version' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            $TestErr | Should BeNullOrEmpty
        }

        It 'Works on manifest major version equal but minor version is less than latest minor version' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            try {
                $plasterModule.Invoke({$script:LatestSupportedSchemaVersion = New-Object System.Version $LatestSupportedSchemaVersion.Major,($LatestSupportedSchemaVersion.Minor+1)})
                Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
                $TestErr | Should BeNullOrEmpty
            }
            finally {
                $plasterModule.Invoke({$script:LatestSupportedSchemaVersion = $SchemaVersion})
            }
        }

        It 'Detects invalid default value for choice parameters' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters>
    <parameter name='License'
                type='choice'
                prompt='Select a license (see http://choosealicense.com for help choosing):'
                default='None'
                store='text'>
        <choice label='&amp;Apache'
                help="Adds an Apache license file."
                value="Apache"/>
        <choice label='&amp;MIT'
                help="Adds an MIT license file."
                value="MIT"/>
        <choice label='&amp;None'
                help="No license."
                value="None"/>
    </parameter>
  </parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $verboseRecord = Test-PlasterManifest -Path $PlasterManifestPath -Verbose -ErrorVariable TestErr -ErrorAction SilentlyContinue 4>&1
            $TestErr | Should Not BeNullOrEmpty
            $verboseRecord | Should Not BeNullOrEmpty
            $verboseRecord.Message | Should Match "attribute value 'None'"
            $verboseRecord.Message | Should Match "a zero-based"
        }

        It 'Detects invalid default value for multichoice parameters' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters>
    <parameter name='Options'
                type='multichoice'
                prompt='Select one or more of the following tooling options:'
                default='Git,psake'
                store='text' >
        <choice label='&amp;Git .gitignore file'
                help="Adds a .gitignore file."
                value="Git"/>
        <choice label='p&amp;sake build script'
                help="Adds psake build script that generates the module directory for publishing to the PowerShell Gallery."
                value="psake"/>
        <choice label='&amp;Pester test support'
                help="Adds test directory and Pester test for the module manifest file."
                value="Pester"/>
        <choice label='PSScript&amp;Analyzer'
                help="Adds script analysis support using PSScriptAnalyzer."
                value="PSScriptAnalyzer"/>
        <choice label='plat&amp;yPS help generator'
                help="Adds help build support using platyPS."
                value="platyPS"/>
        <choice label='&amp;None'
                help="No options specified."
                value="None"/>
    </parameter>
  </parameters>
  <content></content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $verboseRecord = Test-PlasterManifest -Path $PlasterManifestPath -Verbose -ErrorVariable TestErr -ErrorAction SilentlyContinue 4>&1
            $TestErr | Should Not BeNullOrEmpty
            $verboseRecord | Should Not BeNullOrEmpty
            $verboseRecord.Message | Should Match "attribute value 'Git,psake'"
            $verboseRecord.Message | Should Match "one or more zero-based"
        }

        It 'Detects invalid condition attribute value' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content>
  <file condition='"foo" -eq "bar'
        source='Recurse\foo.txt'
        destination='foo.txt'/>
  </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $verboseRecord = Test-PlasterManifest -Path $PlasterManifestPath -Verbose -ErrorVariable TestErr -ErrorAction SilentlyContinue 4>&1
            $TestErr | Should Not BeNullOrEmpty
            $verboseRecord | Should Not BeNullOrEmpty
            $verboseRecord.Message | Should Match "Invalid condition '`"foo`" -eq `"bar'"
        }

        It 'Detects invalid content attribute value' {
            CleanDir $TemplateDir

            @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($SchemaVersion.Major).$($SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content>
  <file source='Recurse\"foo.txt'
        destination='foo.txt'/>
  </content>
</plasterManifest>
"@ | Out-File $PlasterManifestPath -Encoding utf8

            $verboseRecord = Test-PlasterManifest -Path $PlasterManifestPath -Verbose -ErrorVariable TestErr -ErrorAction SilentlyContinue 4>&1
            $TestErr | Should Not BeNullOrEmpty
            $verboseRecord | Should Not BeNullOrEmpty
            $verboseRecord.Message | Should Match "Invalid 'source' attribute value 'Recurse\\`"foo.txt'"
        }
    }
}
