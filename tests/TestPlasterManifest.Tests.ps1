BeforeDiscovery {
  $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
  $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
  $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
  $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
  $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"
  Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
  $global:module = Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop -PassThru

  $global:SchemaVersion = $global:module.Invoke( { $LatestSupportedSchemaVersion })

}
Describe 'Test-PlasterManifest Command Tests' {
  BeforeEach {
    $TemplateDir = "TestDrive:\TemplateRootTemp"
    New-Item -ItemType Directory $TemplateDir | Out-Null
    $OutDir = "TestDrive:\Out"
    New-Item -ItemType Directory $OutDir | Out-Null
    $PlasterManifestPath = "$TemplateDir\plasterManifest.xml"
  }
  AfterEach {
    Remove-Item $PlasterManifestPath -Confirm:$False
    Remove-Item $outDir -Recurse -Confirm:$False
    Remove-Item $TemplateDir -Recurse -Confirm:$False
  }
  Context 'Verifies plasterVersion correctly' {
    It 'Works with the current Plaster version.' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:SchemaVersion" plasterVersion="$($global:module.Version)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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

      Test-PlasterManifest -Path ($PlasterManifestPath -replace 'TestDrive:', (Get-PSDrive TestDrive).Root) -OutVariable xmldoc | Should -Not -BeNullOrEmpty
      $xmldoc.plasterManifest.plasterVersion | Should -Be $global:module.Version
    }

    It 'Errors on manifest plasterVersion greater than the current Plaster version.' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$global:SchemaVersion" plasterVersion="9999.0" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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

      Test-PlasterManifest -Path ($PlasterManifestPath -replace 'TestDrive:', (Get-PSDrive TestDrive).Root) -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
      $TestErr.Exception.Message -match "specifies a plasterVersion of 9999\.0" | Should -Be $true
    }
  }

  Context 'Verifies manifest schema correctly' {
    It 'Errors on manifest major version greater than supported' {
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

      Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
      $TestErr.Exception.Message -match "requires a newer version of Plaster" | Should -Be $true
    }

    It 'Errors on manifest major version equal but minor version greater than supported' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor + 1)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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

      Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
      $TestErr.Exception.Message -match "requires a newer version of Plaster" | Should -Be $true
    }

    It 'Works on manifest major version equal to latest version' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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

      Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
      $TestErr | Should -BeNullOrEmpty
    }

    It 'Works on manifest major version equal but minor version is less than latest minor version' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
        $global:module.Invoke( { $script:LatestSupportedSchemaVersion = New-Object System.Version $LatestSupportedSchemaVersion.Major, ($LatestSupportedSchemaVersion.Minor + 1) })
        Test-PlasterManifest -Path $PlasterManifestPath -ErrorVariable TestErr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        $TestErr | Should -BeNullOrEmpty
      } finally {
        $global:module.Invoke( { $script:LatestSupportedSchemaVersion = $global:SchemaVersion })
      }
    }

    It 'Detects invalid default value for choice parameters' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      $TestErr | Should -Not -BeNullOrEmpty
      $verboseRecord | Should -Not -BeNullOrEmpty
      $verboseRecord.Message | Should -Match "attribute value 'None'"
      $verboseRecord.Message | Should -Match "a zero-based"
    }

    It 'Detects invalid default value for multichoice parameters' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      $TestErr | Should -Not -BeNullOrEmpty
      $verboseRecord | Should -Not -BeNullOrEmpty
      $verboseRecord.Message | Should -Match "attribute value 'Git,psake'"
      $verboseRecord.Message | Should -Match "one or more zero-based"
    }

    It 'Detects invalid condition attribute value' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      $TestErr | Should -Not -BeNullOrEmpty
      $verboseRecord | Should -Not -BeNullOrEmpty
      $verboseRecord.Message | Should -Match "Invalid condition '`"foo`" -eq `"bar'"
    }

    It 'Detects invalid content attribute value' {
      @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="$($global:SchemaVersion.Major).$($global:SchemaVersion.Minor)" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
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
      $TestErr | Should -Not -BeNullOrEmpty
      $verboseRecord | Should -Not -BeNullOrEmpty
      $verboseRecord.Message | Should -Match "Invalid 'source' attribute value 'Recurse\\`"foo.txt'"
    }
  }
}
