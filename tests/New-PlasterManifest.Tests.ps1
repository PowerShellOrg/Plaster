BeforeDiscovery {
    if ($null -eq $env:BHProjectPath) {
        $path = Join-Path -Path $PSScriptRoot -ChildPath '..\build.ps1'
        . $path -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    $module = Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop -PassThru
    # TODO This isn't available in run phase
    # $global:LatestSchemaVersion = $module.Invoke({ $LatestSupportedSchemaVersion })
    $global:LatestSchemaVersion = [System.Version]'1.2'

    function global:GetFullPath {
        param(
            [string] $Path
        )
        return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
    }
    function global:CompareManifestContent($expectedManifest, $actualManifestPath) {
        # Compare the manifests while accounting for possible newline incompatibility
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
  templateType="Item"
  xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
            $newPlasterManifestSplat = @{
                Path = $PlasterManifestPath
                Id = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'TemplateName'
                TemplateType = 'item'
                Format = 'XML'
            }
            New-PlasterManifest @newPlasterManifestSplat
            Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
            global:CompareManifestContent $expectedManifest $PlasterManifestPath
        }

        It 'Properly encodes XML special chars and entity refs' {
            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Project"
  xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
            $newPlasterManifestSplat = @{
                Path = $PlasterManifestPath
                Id = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'TemplateName'
                TemplateType = 'project'
                Description = "This is <cool> & awesome."
                Format = 'XML'
            }
            New-PlasterManifest @newPlasterManifestSplat
            Test-PlasterManifest -Path (global:GetFullPath $PlasterManifestPath) | Should -Not -BeNullOrEmpty
            global:CompareManifestContent $expectedManifest $PlasterManifestPath
        }

        It 'Captures tags correctly' {
            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Item"
  xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
            $newPlasterManifestSplat = @{
                Path = $PlasterManifestPath
                Id = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'TemplateName'
                TemplateType = 'item'
                Tags = "Bag&Tag", 'Foo', 'Bar', "Baz boy"
                Format = 'XML'
            }
            New-PlasterManifest @newPlasterManifestSplat
            Test-PlasterManifest -Path $PlasterManifestPath | Should -Not -BeNullOrEmpty
            global:CompareManifestContent $expectedManifest $PlasterManifestPath
        }

        It 'AddContent parameter works' {
            $separator = if ($IsWindows) { "\" } else { "/" }
            $expectedManifest = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:LatestSchemaVersion"
  templateType="Project"
  xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
"@ -f $separator

            $newPlasterManifestSplat = @{
                Path = $PlasterManifestPath
                Id = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'TemplateName'
                TemplateType = 'project'
                AddContent = $true
                Format = 'XML'
            }
            New-PlasterManifest @newPlasterManifestSplat
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

Describe 'New-PlasterManifest JSON Format Tests' {
    BeforeEach {
        $TemplateDir = "TestDrive:\JsonTemplateDir"
        New-Item -ItemType Directory $TemplateDir | Out-Null
        $PlasterManifestPath = "$TemplateDir\plasterManifest.json"
    }
    AfterEach {
        Remove-Item $TemplateDir -Recurse -Confirm:$false -ErrorAction SilentlyContinue
    }

    Context 'Generates a valid JSON manifest' {
        It 'Creates JSON with basic parameters' {
            $newPlasterManifestSplat = @{
                Path         = $PlasterManifestPath
                Id           = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'JsonTemplate'
                TemplateType = 'Project'
                Format       = 'JSON'
                Author       = 'TestAuthor'
                Description  = 'A JSON test template'
            }
            New-PlasterManifest @newPlasterManifestSplat

            Test-Path $PlasterManifestPath | Should -Be $true
            $content = Get-Content $PlasterManifestPath -Raw | ConvertFrom-Json
            $content.schemaVersion | Should -Be '2.0'
            $content.metadata.name | Should -Be 'JsonTemplate'
            $content.metadata.id | Should -Be '1a1b0933-78b2-4a3e-bf48-492591e69521'
            $content.metadata.version | Should -Be '1.0.0'
            $content.metadata.templateType | Should -Be 'Project'
            $content.metadata.author | Should -Be 'TestAuthor'
            $content.metadata.description | Should -Be 'A JSON test template'
        }

        It 'Handles tags in JSON format' {
            $newPlasterManifestSplat = @{
                Path         = $PlasterManifestPath
                Id           = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'TagTest'
                TemplateType = 'Item'
                Format       = 'JSON'
                Author       = 'Test'
                Tags         = 'Module', 'PowerShell', 'Template'
            }
            New-PlasterManifest @newPlasterManifestSplat

            $content = Get-Content $PlasterManifestPath -Raw | ConvertFrom-Json
            $content.metadata.tags | Should -HaveCount 3
            $content.metadata.tags | Should -Contain 'Module'
            $content.metadata.tags | Should -Contain 'PowerShell'
        }

        It 'JSON manifest does not require XML entity escaping' {
            $newPlasterManifestSplat = @{
                Path         = $PlasterManifestPath
                Id           = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'EscapeTest'
                TemplateType = 'Project'
                Format       = 'JSON'
                Author       = 'Test'
                Description  = 'This is <cool> & awesome.'
            }
            New-PlasterManifest @newPlasterManifestSplat

            $content = Get-Content $PlasterManifestPath -Raw | ConvertFrom-Json
            $content.metadata.description | Should -Be 'This is <cool> & awesome.'
        }

        It 'AddContent parameter works with JSON format' {
            Copy-Item $PSScriptRoot\Recurse $TemplateDir -Recurse

            $newPlasterManifestSplat = @{
                Path         = $PlasterManifestPath
                Id           = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'ContentTest'
                TemplateType = 'Project'
                Format       = 'JSON'
                Author       = 'Test'
                AddContent   = $true
            }
            New-PlasterManifest @newPlasterManifestSplat

            $content = Get-Content $PlasterManifestPath -Raw | ConvertFrom-Json
            $content.content.Count | Should -BeGreaterThan 0
            $content.content[0].type | Should -Be 'file'
            $content.content[0].source | Should -Not -BeNullOrEmpty
        }

        It 'Defaults to JSON format when Format not specified' {
            $defaultPath = "$TemplateDir\plasterManifest.json"
            $newPlasterManifestSplat = @{
                Path         = $defaultPath
                Id           = '1a1b0933-78b2-4a3e-bf48-492591e69521'
                TemplateName = 'DefaultFormat'
                TemplateType = 'Item'
                Author       = 'Test'
            }
            New-PlasterManifest @newPlasterManifestSplat

            Test-Path $defaultPath | Should -Be $true
            $content = Get-Content $defaultPath -Raw | ConvertFrom-Json
            $content.schemaVersion | Should -Be '2.0'
        }
    }
}
