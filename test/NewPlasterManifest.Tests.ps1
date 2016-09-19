. $PSScriptRoot\Shared.ps1

Describe 'New-PlasterManifest Command Tests' {
    Context 'Generates a valid manifest' {
        It 'Works with just Path and Id' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title></title>
    <description></description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521'
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            $actualManifest = Get-Content $plasterPath -Raw
            $actualManifest | Should BeExactly $expectedManifest
        }

        It 'Properly encode XML special chars and entity refs' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title></title>
    <description>This is &lt;cool&gt; &amp; awesome.</description>
    <author></author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -Description "This is <cool> & awesome."
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            $actualManifest = Get-Content $plasterPath -Raw
            $actualManifest | Should BeExactly $expectedManifest
        }

        It 'Captures tags correctly' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title></title>
    <description></description>
    <author></author>
    <tags>Bag&amp;Tag, Foo, Bar, Baz boy</tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
"@
            $plasterPath = "$OutDir\plasterManifest.xml"
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -Tags "Bag&Tag", Foo, Bar, "Baz boy"
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            $actualManifest = Get-Content $plasterPath -Raw
            $actualManifest | Should BeExactly $expectedManifest
        }

        It 'AddContent parameter works' {
            CleanDir $TemplateDir
            CleanDir $OutDir

            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <id>1a1b0933-78b2-4a3e-bf48-492591e69521</id>
    <version>1.0.0</version>
    <title></title>
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
            New-PlasterManifest -Path $plasterPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -AddContent
            Test-PlasterManifest -Path $plasterPath | Should Not BeNullOrEmpty
            $actualManifest = Get-Content $plasterPath -Raw
            $actualManifest | Should BeExactly $expectedManifest
        }
    }
}
