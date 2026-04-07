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

Describe 'JSON Manifest Support' {
    BeforeEach {
        $TemplateDir = "TestDrive:\JsonTemplateDir"
        New-Item -ItemType Directory $TemplateDir | Out-Null
        $OutDir = "TestDrive:\JsonOut"
        New-Item -ItemType Directory $OutDir | Out-Null
    }
    AfterEach {
        Remove-Item $OutDir -Recurse -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item $TemplateDir -Recurse -Confirm:$false -ErrorAction SilentlyContinue
    }

    Context 'Test-PlasterManifest with JSON' {
        It 'Validates a well-formed JSON manifest' {
            $jsonManifest = @{
                '$schema'       = 'https://raw.githubusercontent.com/PowerShellOrg/Plaster/v2/schema/plaster-manifest-v2.json'
                schemaVersion   = '2.0'
                metadata        = @{
                    name         = 'TestTemplate'
                    id           = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version      = '1.0.0'
                    title        = 'Test Template'
                    description  = 'A test template'
                    author       = 'Test Author'
                    templateType = 'Project'
                }
                parameters      = @()
                content         = @(
                    @{
                        type = 'message'
                        text = 'Hello from JSON template'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $result | Should -Not -BeNullOrEmpty
            $result.plasterManifest | Should -Not -BeNullOrEmpty
        }

        It 'Rejects JSON manifest with missing required metadata' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name = 'TestTemplate'
                    # Missing: id, version, title, author
                }
                content       = @(
                    @{
                        type = 'message'
                        text = 'Hello'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            { Test-PlasterManifest -Path $jsonPath -ErrorAction Stop } | Should -Throw
        }

        It 'Rejects JSON manifest with invalid schema version' {
            $jsonManifest = @{
                schemaVersion = '99.0'
                metadata      = @{
                    name    = 'TestTemplate'
                    id      = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version = '1.0.0'
                    title   = 'Test Template'
                    author  = 'Test Author'
                }
                content       = @(
                    @{
                        type = 'message'
                        text = 'Hello'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            { Test-PlasterManifest -Path $jsonPath -ErrorAction Stop } | Should -Throw
        }

        It 'Rejects JSON manifest with invalid GUID' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name    = 'TestTemplate'
                    id      = 'not-a-guid'
                    version = '1.0.0'
                    title   = 'Test Template'
                    author  = 'Test Author'
                }
                content       = @(
                    @{
                        type = 'message'
                        text = 'Hello'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            { Test-PlasterManifest -Path $jsonPath -ErrorAction Stop } | Should -Throw
        }
    }

    Context 'ConvertFrom-JsonManifest' {
        It 'Converts JSON manifest to XML document via Test-PlasterManifest' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name         = 'MyTemplate'
                    id           = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version      = '1.0.0'
                    title        = 'My Template'
                    description  = 'A template'
                    author       = 'Author'
                    templateType = 'Item'
                }
                parameters    = @()
                content       = @(
                    @{
                        type = 'message'
                        text = 'Done'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $result | Should -Not -BeNullOrEmpty
            $result.plasterManifest.metadata.name | Should -Be 'MyTemplate'
            $result.plasterManifest.metadata.id | Should -Be '513d2fdc-3cce-47d9-9531-d85114efb224'
        }

        It 'Converts parameters with choices correctly' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name    = 'ChoiceTemplate'
                    id      = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version = '1.0.0'
                    title   = 'Choice Test'
                    author  = 'Author'
                }
                parameters    = @(
                    @{
                        name    = 'License'
                        type    = 'choice'
                        prompt  = 'Select a license'
                        default = '0'
                        choices = @(
                            @{ label = '&MIT'; value = 'MIT' },
                            @{ label = '&Apache'; value = 'Apache' }
                        )
                    }
                )
                content       = @(
                    @{
                        type = 'message'
                        text = 'Done'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $paramNode = $result.plasterManifest.parameters.parameter
            $paramNode.name | Should -Be 'License'
            $paramNode.type | Should -Be 'choice'
            $paramNode.ChildNodes.Count | Should -Be 2
            $paramNode.ChildNodes[0].value | Should -Be 'MIT'
        }

        It 'Converts multichoice array defaults to comma-separated string' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name    = 'MultiTemplate'
                    id      = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version = '1.0.0'
                    title   = 'Multi Test'
                    author  = 'Author'
                }
                parameters    = @(
                    @{
                        name    = 'Features'
                        type    = 'multichoice'
                        prompt  = 'Select features'
                        default = @(0, 2)
                        choices = @(
                            @{ label = '&Tests'; value = 'Tests' },
                            @{ label = '&Docs'; value = 'Docs' },
                            @{ label = '&CI'; value = 'CI' }
                        )
                    }
                )
                content       = @(
                    @{
                        type = 'message'
                        text = 'Done'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $paramNode = $result.plasterManifest.parameters.parameter
            $paramNode.default | Should -Be '0,2'
        }

        It 'Converts tags array to comma-separated string' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name    = 'TagTemplate'
                    id      = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version = '1.0.0'
                    title   = 'Tag Test'
                    author  = 'Author'
                    tags    = @('Module', 'PowerShell', 'Template')
                }
                parameters    = @()
                content       = @(
                    @{
                        type = 'message'
                        text = 'Done'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $result.plasterManifest.metadata.tags | Should -Be 'Module, PowerShell, Template'
        }
    }

    Context 'Manifest format detection' {
        It 'Test-PlasterManifest accepts JSON files' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name    = 'Test'
                    id      = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version = '1.0.0'
                    title   = 'Test'
                    author  = 'Author'
                }
                content       = @(
                    @{ type = 'message'; text = 'Hi' }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $result = Test-PlasterManifest -Path $jsonPath
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Test-PlasterManifest accepts XML files' {
            $xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="1.2" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <name>Test</name>
        <id>513d2fdc-3cce-47d9-9531-d85114efb224</id>
        <version>1.0.0</version>
        <title>Test</title>
        <description></description>
        <author></author>
        <tags></tags>
    </metadata>
    <parameters></parameters>
    <content></content>
</plasterManifest>
"@
            $xmlPath = Join-Path $TemplateDir 'plasterManifest.xml'
            Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8

            $result = Test-PlasterManifest -Path $xmlPath
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-Plaster with JSON manifest' {
        It 'Processes a simple JSON template with message action' {
            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name         = 'SimpleJson'
                    id           = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version      = '1.0.0'
                    title        = 'Simple JSON Template'
                    description  = 'Test template'
                    author       = 'Test'
                    templateType = 'Project'
                }
                parameters    = @(
                    @{
                        name    = 'ProjectName'
                        type    = 'text'
                        prompt  = 'Project name'
                        default = 'TestProject'
                    }
                )
                content       = @(
                    @{
                        type = 'message'
                        text = 'Creating project ${PLASTER_PARAM_ProjectName}'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $DestPath = Join-Path $OutDir 'SimpleJsonProject'
            $result = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -ProjectName 'MyProject' -NoLogo -Force -PassThru
            $result.Success | Should -Be $true
            $result.ManifestType | Should -Be 'JSON'
        }

        It 'Copies files from a JSON template' {
            # Create source file in template dir
            Set-Content -Path (Join-Path $TemplateDir 'hello.txt') -Value 'Hello World'

            $jsonManifest = @{
                schemaVersion = '2.0'
                metadata      = @{
                    name         = 'FileJson'
                    id           = '513d2fdc-3cce-47d9-9531-d85114efb224'
                    version      = '1.0.0'
                    title        = 'File Copy JSON Template'
                    description  = 'Test file copy'
                    author       = 'Test'
                    templateType = 'Item'
                }
                parameters    = @()
                content       = @(
                    @{
                        type        = 'file'
                        source      = 'hello.txt'
                        destination = 'hello.txt'
                    }
                )
            }
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            $jsonManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

            $DestPath = Join-Path $OutDir 'FileCopyTest'
            $result = Invoke-Plaster -TemplatePath $TemplateDir -DestinationPath $DestPath -NoLogo -Force -PassThru
            $result.Success | Should -Be $true
            Test-Path (Join-Path $DestPath 'hello.txt') | Should -Be $true
            Get-Content (Join-Path $DestPath 'hello.txt') | Should -Be 'Hello World'
        }
    }

    Context 'New-PlasterManifest JSON format' {
        It 'Creates a valid JSON manifest file' {
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            New-PlasterManifest -Path $jsonPath -TemplateName 'TestMod' -TemplateType Project -Format JSON `
                -Id '513d2fdc-3cce-47d9-9531-d85114efb224' -Author 'Tester' -Description 'Test desc'

            Test-Path $jsonPath | Should -Be $true
            $content = Get-Content $jsonPath -Raw | ConvertFrom-Json
            $content.schemaVersion | Should -Be '2.0'
            $content.metadata.name | Should -Be 'TestMod'
            $content.metadata.templateType | Should -Be 'Project'
            $content.metadata.author | Should -Be 'Tester'
        }

        It 'Creates a valid XML manifest when Format is XML' {
            $xmlPath = Join-Path $TemplateDir 'plasterManifest.xml'
            New-PlasterManifest -Path $xmlPath -TemplateName 'TestMod' -TemplateType Item -Format XML `
                -Id '513d2fdc-3cce-47d9-9531-d85114efb224'

            Test-Path $xmlPath | Should -Be $true
            $result = Test-PlasterManifest -Path $xmlPath
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Defaults to JSON format' {
            $jsonPath = Join-Path $TemplateDir 'plasterManifest.json'
            New-PlasterManifest -Path $jsonPath -TemplateName 'DefaultFmt' -TemplateType Item `
                -Id '513d2fdc-3cce-47d9-9531-d85114efb224' -Author 'Tester'

            $content = Get-Content $jsonPath -Raw | ConvertFrom-Json
            $content.schemaVersion | Should -Be '2.0'
        }
    }
}
