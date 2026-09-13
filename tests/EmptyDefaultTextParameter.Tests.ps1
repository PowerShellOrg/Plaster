BeforeDiscovery {
    if ($null -eq $env:BHProjectPath) {
        $path = Join-Path -Path $PSScriptRoot -ChildPath '..\build.ps1'
        . $path -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path $outputModVerDir "$($env:BHProjectName).psd1"
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}

Describe 'Empty text parameter defaults' -Tag 'Unit' {
    InModuleScope $env:BHProjectName {
        It 'preserves an explicit empty JSON default' {
            $manifest = ConvertFrom-JsonManifest -JsonContent @'
{
    "schemaVersion": "2.0",
    "metadata": {
        "name": "EmptyDefault",
        "id": "513d2fdc-3cce-47d9-9531-d85114efb224",
        "version": "1.0.0",
        "title": "Empty default",
        "description": "Tests explicit empty defaults.",
        "author": "Plaster",
        "tags": ["Test"]
    },
    "parameters": [
        {
            "name": "ModuleDesc",
            "type": "text",
            "prompt": "Enter a description",
            "default": ""
        }
    ],
    "content": [
        {
            "type": "file",
            "source": "source.txt",
            "destination": "source.txt"
        }
    ]
}
'@

            $parameter = $manifest.plasterManifest.parameters.parameter
            $parameter.HasAttribute('default') | Should -BeTrue
            $parameter.default | Should -BeExactly ''
        }

        It 'accepts blank input when an empty default is explicit' {
            $script:responses = [System.Collections.Generic.Queue[string]]::new()
            $script:responses.Enqueue('')
            $script:responses.Enqueue('unexpected second prompt')
            Mock Read-Host { $script:responses.Dequeue() }

            $result = Read-PromptForInput -prompt 'Enter a description' -default '' -AllowEmpty

            $result | Should -BeExactly ''
            Should -Invoke Read-Host -Times 1 -Exactly
        }
        It 'completes a JSON template when its text default is empty' {
            $templatePath = Join-Path $TestDrive 'template'
            $destinationPath = Join-Path $TestDrive 'output'
            New-Item -ItemType Directory -Path $templatePath | Out-Null
            @'
{
    "schemaVersion": "2.0",
    "metadata": {
        "name": "EmptyDefault",
        "id": "513d2fdc-3cce-47d9-9531-d85114efb224",
        "version": "1.0.0",
        "title": "Empty default",
        "description": "Tests explicit empty defaults.",
        "author": "Plaster",
        "tags": ["Test"]
    },
    "parameters": [
        {
            "name": "ModuleDesc",
            "type": "text",
            "prompt": "Enter a description",
            "default": ""
        }
    ],
    "content": [
        {
            "type": "templateFile",
            "source": "description.txt",
            "destination": "description.txt"
        }
    ]
}
'@ | Set-Content -LiteralPath (Join-Path $templatePath 'plasterManifest.json') -Encoding utf8
            '<%=$PLASTER_PARAM_ModuleDesc%>' | Set-Content -LiteralPath (Join-Path $templatePath 'description.txt') -Encoding utf8
            Mock Read-Host { '' }

            Invoke-Plaster -TemplatePath $templatePath -DestinationPath $destinationPath -NoLogo

            (Get-Content -LiteralPath (Join-Path $destinationPath 'description.txt') -Raw).Trim() | Should -BeExactly ''
            Should -Invoke Read-Host -Times 1 -Exactly
        }
    }
}
