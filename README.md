# Plaster

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/Plaster.svg)](https://www.powershellgallery.com/packages/Plaster)
[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/Plaster.svg)](https://www.powershellgallery.com/packages/Plaster)
[![Build Status](https://github.com/PowerShell/Plaster/workflows/CI/badge.svg)](https://github.com/PowerShell/Plaster/actions)

Plaster is a template-based file and project generator written in PowerShell. Its purpose is to streamline the creation of PowerShell module projects, Pester tests, DSC configurations, and more. File generation is performed using crafted templates which allow the user to fill in details and choose from options to get their desired output.

## What's New in Plaster 2.0

Plaster 2.0 introduces **JSON manifest support** alongside the traditional XML format, bringing modern tooling and improved developer experience:

### 🆕 JSON Manifest Format
- **Modern Syntax**: Clean, readable JSON instead of verbose XML
- **Better Tooling**: VS Code IntelliSense with JSON Schema validation
- **Simplified Variables**: Use `${ParameterName}` instead of `${PLASTER_PARAM_ParameterName}`
- **Native Arrays**: No more comma-separated strings for multichoice defaults
- **No Escaping**: No XML entity escaping required (`&` instead of `&amp;`)

### 🔄 Backwards Compatibility
- **Zero Breaking Changes**: All existing XML templates continue to work
- **Automatic Detection**: Plaster automatically detects and processes both formats
- **Side-by-Side Support**: Templates can include both XML and JSON manifests
- **Seamless Migration**: Convert existing XML templates to JSON when ready

### 📊 Format Comparison

| Feature | XML Format | JSON Format |
|---------|------------|-------------|
| Compatibility | Plaster 1.x+ | Plaster 2.0+ |
| Variable Syntax | `${PLASTER_PARAM_Name}` | `${Name}` |
| Multichoice Defaults | `"0,1,2"` | `[0, 1, 2]` |
| Schema Validation | ✅ XSD | ✅ JSON Schema |
| VS Code IntelliSense | Limited | Full Support |
| Special Characters | Requires escaping | No escaping needed |

## Installation

### From PowerShell Gallery (Recommended)
```powershell
Install-Module -Name Plaster -Scope CurrentUser
```

### From Source
```powershell
git clone https://github.com/PowerShell/Plaster.git
Import-Module .\Plaster\Plaster\Plaster.psd1
```

## Quick Start

### Using an Existing Template
```powershell
# Discover available templates
Get-PlasterTemplate

# Create a new PowerShell module (interactive)
$template = Get-PlasterTemplate | Where-Object Name -eq NewPowerShellModule
Invoke-Plaster -TemplatePath $template.TemplatePath -DestinationPath .\MyNewModule

# Non-interactive with parameters
Invoke-Plaster -TemplatePath $template.TemplatePath -DestinationPath .\MyModule `
    -ModuleName 'MyModule' -ModuleDesc 'My awesome module' -Version '1.0.0' `
    -FullName 'Your Name' -License MIT -Options Git,Pester,PSScriptAnalyzer
```

### Creating Your First Template

#### Option 1: JSON Format (Recommended for new templates)
```powershell
# Create a new JSON manifest
New-PlasterManifest -TemplateName MyTemplate -TemplateType Project -Format JSON

# Edit the generated plasterManifest.json with VS Code for full IntelliSense
code plasterManifest.json
```

#### Option 2: XML Format (Traditional)
```powershell
# Create a new XML manifest
New-PlasterManifest -TemplateName MyTemplate -TemplateType Project

# Edit the generated plasterManifest.xml
code plasterManifest.xml
```

### JSON Manifest Example
```json
{
  "$schema": "https://raw.githubusercontent.com/PowerShell/Plaster/v2/schema/plaster-manifest-v2.json",
  "schemaVersion": "2.0",
  "metadata": {
    "name": "MyTemplate",
    "title": "My PowerShell Template",
    "description": "Creates a new PowerShell project",
    "version": "1.0.0",
    "templateType": "Project"
  },
  "parameters": [
    {
      "name": "ProjectName",
      "type": "text",
      "prompt": "Enter the project name"
    },
    {
      "name": "Features",
      "type": "multichoice",
      "prompt": "Select features to include",
      "default": [0, 1],
      "choices": [
        {"label": "&Tests", "value": "Tests"},
        {"label": "&Build Script", "value": "Build"}
      ]
    }
  ],
  "content": [
    {
      "type": "file",
      "source": "template.ps1",
      "destination": "${ProjectName}.ps1"
    }
  ]
}
```

## Core Concepts

### Templates
Templates are directories containing:
- **Manifest File**: `plasterManifest.xml` or `plasterManifest.json` (or both)
- **Source Files**: Files and directories to be copied/processed
- **Template Files**: Files with variable substitution (using `<%=` and `%>` delimiters)

### Parameters
Define user inputs with various types:
- **text**: Free-form text input
- **choice**: Single selection from options
- **multichoice**: Multiple selections from options
- **user-fullname**: User's full name (with git integration)
- **user-email**: User's email (with git integration)

### Content Actions
Define what the template does:
- **file**: Copy files/directories
- **templateFile**: Copy and expand template files
- **modify**: Modify existing files with search/replace
- **newModuleManifest**: Generate PowerShell module manifests
- **requireModule**: Verify required modules are installed
- **message**: Display messages to users

## Migration Guide

### Converting XML to JSON
```powershell
# Automatic conversion
$xmlManifest = Test-PlasterManifest -Path .\plasterManifest.xml
ConvertTo-JsonManifest -InputObject $xmlManifest -OutputPath .\plasterManifest.json

# Or use New-PlasterManifest with conversion
New-PlasterManifest -TemplateName MyTemplate -TemplateType Project -ConvertFromXml
```

### Variable Syntax Updates
When converting to JSON, update variable references:

**XML Format:**
```xml
<file source="template.ps1" destination="${PLASTER_PARAM_ModuleName}.ps1"/>
```

**JSON Format:**
```json
{
  "type": "file",
  "source": "template.ps1",
  "destination": "${ModuleName}.ps1"
}
```

## Advanced Features

### Conditional Logic
```json
{
  "type": "file",
  "source": "tests.ps1",
  "destination": "Tests/${ProjectName}.Tests.ps1",
  "condition": "${Features} -contains 'Tests'"
}
```

### Pattern Validation
```json
{
  "name": "ModuleName",
  "type": "text",
  "pattern": "^[A-Za-z][A-Za-z0-9_]*$",
  "prompt": "Enter a valid module name"
}
```

### Localization
Create culture-specific manifests:
- `plasterManifest.json` (default)
- `plasterManifest_fr-FR.json` (French)
- `plasterManifest_de-DE.json` (German)

### Module Integration
Embed templates in PowerShell modules:
```powershell
# Module manifest (*.psd1)
PrivateData = @{
    PSData = @{
        Extensions = @(
            @{
                Module = "Plaster"
                MinimumVersion = "2.0.0"
                Details = @{
                    TemplatePaths = @("Templates")
                }
            }
        )
    }
}
```

## Examples

The `examples` directory contains comprehensive examples:

- **NewModuleTemplate**: Full-featured module template (XML + JSON)
- **NewModule**: Simplified module template
- **NewDscResourceScript**: DSC resource template
- **TemplateModule**: PowerShell module with embedded templates
- **Validation Examples**: Input validation patterns
- **Localization Examples**: Multi-language support

## Documentation

- **Getting Started**: `Get-Help about_Plaster`
- **Creating XML Manifests**: `Get-Help about_Plaster_CreatingAManifest`
- **Creating JSON Manifests**: `Get-Help about_Plaster_CreatingJsonManifest`
- **Cmdlet Reference**: `Get-Help Invoke-Plaster`, `Get-Help New-PlasterManifest`

## Editor Integration

### Visual Studio Code
- **JSON Schema**: Automatic validation and IntelliSense for JSON manifests
- **PowerShell Extension**: Template discovery and scaffolding support
- **File Association**: Associate `.json` files with Plaster schema

### PowerShell ISE
- **Template Discovery**: Built-in template browser
- **Parameter Input**: GUI for template parameters

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```powershell
git clone https://github.com/PowerShell/Plaster.git
cd Plaster
Import-Module .\Plaster\Plaster.psd1
Invoke-Pester # Run tests
```

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Related Projects

- **PowerShell**: https://github.com/PowerShell/PowerShell
- **Pester**: https://github.com/pester/Pester
- **PSScriptAnalyzer**: https://github.com/PowerShell/PSScriptAnalyzer
- **platyPS**: https://github.com/PowerShell/platyPS

---

**Plaster 2.0** - Modern template scaffolding for PowerShell with JSON support, better tooling, and enhanced developer experience. 🚀
