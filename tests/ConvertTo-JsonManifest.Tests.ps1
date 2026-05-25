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
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}

Describe 'ConvertTo-JsonManifest' {

    BeforeAll {
        $script:MinimalXml = @'
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="1.1" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>TestTemplate</name>
    <id>00000000-0000-0000-0000-000000000001</id>
    <version>1.0.0</version>
    <title>Test Template</title>
    <description>A test template</description>
    <author>Tester</author>
    <tags></tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
'@
        function script:New-XmlManifest {
            param([string]$Xml = $script:MinimalXml)
            $doc = New-Object System.Xml.XmlDocument
            $doc.LoadXml($Xml)
            $doc
        }
    }

    Context 'Output format' {
        It 'Returns a non-empty string' {
            $result = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest)
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Output is valid JSON' {
            $result = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest)
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Includes the $schema and schemaVersion fields' {
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) | ConvertFrom-Json
            $json.'$schema' | Should -Not -BeNullOrEmpty
            $json.schemaVersion | Should -Be '2.0'
        }

        It 'Produces indented output by default' {
            $result = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest)
            $result | Should -Match "`n"
        }

        It 'Produces compact output with -Compress' {
            $result = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) -Compress
            $result | Should -Not -Match "`n"
        }

        It 'Accepts input from the pipeline' {
            $result = New-XmlManifest | ConvertTo-JsonManifest
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    Context 'Metadata mapping' {
        It 'Maps standard metadata fields' {
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) | ConvertFrom-Json
            $json.metadata.name        | Should -Be 'TestTemplate'
            $json.metadata.version     | Should -Be '1.0.0'
            $json.metadata.title       | Should -Be 'Test Template'
            $json.metadata.description | Should -Be 'A test template'
            $json.metadata.author      | Should -Be 'Tester'
        }

        It 'Defaults templateType to Project when not specified' {
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) | ConvertFrom-Json
            $json.metadata.templateType | Should -Be 'Project'
        }

        It 'Preserves an explicit templateType attribute' {
            $xml = $script:MinimalXml -replace '<plasterManifest ', '<plasterManifest templateType="Item" '
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.metadata.templateType | Should -Be 'Item'
        }

        It 'Splits comma-separated tags into an array' {
            $xml = $script:MinimalXml -replace '<tags></tags>', '<tags>PowerShell, Module, Scaffold</tags>'
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.metadata.tags | Should -HaveCount 3
            $json.metadata.tags | Should -Contain 'PowerShell'
            $json.metadata.tags | Should -Contain 'Module'
            $json.metadata.tags | Should -Contain 'Scaffold'
        }
    }

    Context 'Parameters mapping' {
        It 'Omits the parameters key when there are no parameters' {
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) | ConvertFrom-Json
            $json.PSObject.Properties.Name | Should -Not -Contain 'parameters'
        }

        It 'Maps a simple text parameter' {
            $xml = $script:MinimalXml -replace '<parameters></parameters>', @'
<parameters>
  <parameter name="ModuleName" type="text" prompt="Module name" default="MyModule" store="text" />
</parameters>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.parameters | Should -HaveCount 1
            $p = $json.parameters[0]
            $p.name    | Should -Be 'ModuleName'
            $p.type    | Should -Be 'text'
            $p.prompt  | Should -Be 'Module name'
            $p.default | Should -Be 'MyModule'
            $p.store   | Should -Be 'text'
        }

        It 'Maps a choice parameter with choices' {
            $xml = $script:MinimalXml -replace '<parameters></parameters>', @'
<parameters>
  <parameter name="License" type="choice" prompt="License type" default="0">
    <choice label="MIT" value="MIT" help="MIT License" />
    <choice label="Apache" value="Apache" />
  </parameter>
</parameters>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $p = $json.parameters[0]
            $p.name | Should -Be 'License'
            $p.type | Should -Be 'choice'
            $p.choices | Should -HaveCount 2
            $p.choices[0].label | Should -Be 'MIT'
            $p.choices[0].value | Should -Be 'MIT'
            $p.choices[0].help  | Should -Be 'MIT License'
            $p.choices[1].label | Should -Be 'Apache'
        }

        It 'Splits multichoice defaults into an array' {
            $xml = $script:MinimalXml -replace '<parameters></parameters>', @'
<parameters>
  <parameter name="Options" type="multichoice" prompt="Pick options" default="0,1">
    <choice label="A" value="A" />
    <choice label="B" value="B" />
  </parameter>
</parameters>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.parameters[0].default | Should -HaveCount 2
        }

        It 'Includes condition when present' {
            $xml = $script:MinimalXml -replace '<parameters></parameters>', @'
<parameters>
  <parameter name="Opt" type="text" prompt="Optional" condition='$PLASTER_PARAM_AddOpt -eq "Yes"' />
</parameters>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.parameters[0].condition | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Content mapping' {
        It 'Emits an empty content array when there is no content' {
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest) | ConvertFrom-Json
            $json.PSObject.Properties.Name | Should -Contain 'content'
            $json.content | Should -HaveCount 0
        }

        It 'Maps a file action' {
            $xml = $script:MinimalXml -replace '<content></content>', @'
<content>
  <file source="src\module.psm1" destination="src\${PLASTER_PARAM_ModuleName}.psm1" />
</content>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $action = $json.content[0]
            $action.type        | Should -Be 'file'
            $action.source      | Should -Be 'src\module.psm1'
            $action.destination | Should -Be 'src\${PLASTER_PARAM_ModuleName}.psm1'
        }

        It 'Maps a templateFile action' {
            $xml = $script:MinimalXml -replace '<content></content>', @'
<content>
  <templateFile source="README.md" destination="README.md" />
</content>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $json.content[0].type | Should -Be 'templateFile'
        }

        It 'Maps a message action' {
            $xml = $script:MinimalXml -replace '<content></content>', @'
<content>
  <message>Template scaffolded successfully.</message>
</content>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $action = $json.content[0]
            $action.type | Should -Be 'message'
            $action.text | Should -Be 'Template scaffolded successfully.'
        }

        It 'Maps a requireModule action' {
            $xml = $script:MinimalXml -replace '<content></content>', @'
<content>
  <requireModule name="Pester" minimumVersion="5.0.0" />
</content>
'@
            $json = ConvertTo-JsonManifest -XmlManifest (New-XmlManifest -Xml $xml) | ConvertFrom-Json
            $action = $json.content[0]
            $action.type           | Should -Be 'requireModule'
            $action.name           | Should -Be 'Pester'
            $action.minimumVersion | Should -Be '5.0.0'
        }
    }
}
