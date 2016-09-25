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
    }
}
