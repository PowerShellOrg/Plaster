BeforeDiscovery {
  $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
  $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
  $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
  $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
  $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
  Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
  $module = Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop -PassThru

  $global:LatestSchemaVersion = $module.Invoke( { $LatestSupportedSchemaVersion })
  function global:GetFullPath {
    Param(
      [string] $Path
    )
    return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
  }
  function global:CompareManifestContent($expectedManifest, $actualManifestPath) {
    # Compare the manifests while accounting for possible newline incompatiblity
    $expectedManifest = $expectedManifest -replace "`r`n", "`n"
    $actualManifest = (Get-Content $actualManifestPath -Raw) -replace "`r`n", "`n"
    $actualManifest | Should -BeExactly $expectedManifest
  }
}
Describe 'New-PlasterManifest Command Tests' {
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
  Context 'Generates a valid manifest' {
    It 'Works with just Path, TemplateName, TemplateType and Id' {
      $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Item" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      New-PlasterManifest -Path $PlasterManifestPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName -TemplateType item
      Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
      global:CompareManifestContent $expectedManifest $PlasterManifestPath
    }

    It 'Properly encodes XML special chars and entity refs' {
      $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Project" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      New-PlasterManifest -Path $PlasterManifestPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName `
        -TemplateType project -Description "This is <cool> & awesome."
      Test-PlasterManifest -Path (global:GetFullPath $PlasterManifestPath) | Should -Not -BeNullOrEmpty
      global:CompareManifestContent $expectedManifest $PlasterManifestPath
    }

    It 'Captures tags correctly' {
      $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Item" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      New-PlasterManifest -Path $PlasterManifestPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName `
        -TemplateType item -Tags "Bag&Tag", Foo, Bar, "Baz boy"
      Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
      global:CompareManifestContent $expectedManifest $PlasterManifestPath
    }

    It 'AddContent parameter works' {
      $seperator = if ($IsWindows) { "\" } else { "/" }
      $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Project" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      source="Recurse{0}empty.txt"
      destination="Recurse{0}empty.txt" />
    <file
      source="Recurse{0}foo.txt"
      destination="Recurse{0}foo.txt" />
    <file
      source="Recurse{0}a{0}bar.txt"
      destination="Recurse{0}a{0}bar.txt" />
    <file
      source="Recurse{0}a{0}b{0}baz.txt"
      destination="Recurse{0}a{0}b{0}baz.txt" />
    <file
      source="Recurse{0}a{0}c{0}test.ini"
      destination="Recurse{0}a{0}c{0}test.ini" />
    <file
      source="Recurse{0}a{0}c{0}d{0}gilead.txt"
      destination="Recurse{0}a{0}c{0}d{0}gilead.txt" />
  </content>
</plasterManifest>
"@ -f $seperator

      New-PlasterManifest -Path $PlasterManifestPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName `
        -TemplateType project -AddContent
      Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
      global:CompareManifestContent $expectedManifest $PlasterManifestPath
    }
  }
  <#
  Context 'Parameter tests' {
    Not sure the actual value of this, since it would be testing PowerShell
    understanding of tilde. This is difficult to test in Pester 5, and I'm not
    sure what value it's providing - HeyItsGilbert

    It 'Path resolves ~' {
      $PlasterManifestPath = "~\plasterManifest.xml"
      Remove-Item $PlasterManifestPath -ErrorAction SilentlyContinue
      if (Test-Path $PlasterManifestPath) {
        throw "$plasterManifest should have been removed for this test to work correctly."
      }
      New-PlasterManifest -Path $PlasterManifestPath -Id '1a1b0933-78b2-4a3e-bf48-492591e69521' -TemplateName TemplateName `
        -TemplateType item
      Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
    }
  }
  #>
}
