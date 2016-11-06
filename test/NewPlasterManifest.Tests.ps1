. $PSScriptRoot\Shared.ps1

function CompareManifestContent($expectedManifest, $actualManifestPath) {
    # Compare the manifests while accounting for possible newline incompatiblity
    $expectedManifest = $expectedManifest -replace "`r`n", "`n"
    $actualManifest = (Get-Content $plasterPath -Raw) -replace "`r`n", "`n"
    $actualManifest | Should BeExactly $expectedManifest
}

Describe 'New-PlasterManifest Command Tests' {
    Context 'Generates a valid manifest' {
        It 'Works with just Path, Name and Id' {
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            CompareManifestContent $expectedManifest $plasterPath
        }

        It 'Properly encodes XML special chars and entity refs' {
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description>This is &lt;cool&gt; &amp; awesome.</description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName -Description "This is <cool> & awesome."
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            CompareManifestContent $expectedManifest $plasterPath
        }

        It 'Captures tags correctly' {
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TemplateName</name>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title>TemplateName</title>
    <description></description>
    <author></author>
    <tags>Bag&amp;Tag, Foo, Bar, Baz boy</tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName -Tags "Bag&Tag", Foo, Bar, "Baz boy"
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            CompareManifestContent $expectedManifest $plasterPath
        }

        It 'AddContent parameter works' {
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
    <file
      source="Recurse\empty.txt"
      destination="Recurse\empty.txt" />
    <file
      source="Recurse\foo.txt"
      destination="Recurse\foo.txt" />
    <file
      source="Recurse\a\bar.txt"
      destination="Recurse\a\bar.txt" />
    <file
      source="Recurse\a\b\baz.txt"
      destination="Recurse\a\b\baz.txt" />
    <file
      source="Recurse\a\c\test.ini"
      destination="Recurse\a\c\test.ini" />
    <file
      source="Recurse\a\c\d\gilead.txt"
      destination="Recurse\a\c\d\gilead.txt" />
  </content>
</plasterManifest>
"@

            $plasterPath = "$OutDir\plasterManifest.xml"
            Copy-Item $PSScriptRoot\Recurse $OutDir -Recurse
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName -AddContent
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            CompareManifestContent $expectedManifest $plasterPath
        }
    }

    Context 'Parameter tests' {
        It 'Path resolves ~' {
            $plasterPath = "~\plasterManifest.xml"
            Remove-Item $plasterPath -ErrorAction SilentlyContinue
            if (Test-Path $plasterPath) {
                throw "$plasterManifest should have been removed for this test to work correctly."
            }
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
        }
    }
}
