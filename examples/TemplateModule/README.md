# Plaster Examples

## NewModuleTemplate

This example demonstrates a template used for scaffolding a new module project. It has support for Git, PSake build script, and Pester tests.

### Using XML Format (Traditional)

The template includes both XML and JSON manifest formats:
- `plasterManifest.xml` - Traditional XML format (backwards compatible)
- `plasterManifest.json` - Modern JSON format (Plaster 2.0+)

To run this example using XML format:
```powershell
Import-Module ..\..\Plaster\Plaster.psd1
Invoke-Plaster -TemplatePath . -DestinationPath ..\Out
```

### Using JSON Format (Plaster 2.0+)

To run this example using the new JSON format:
```powershell
Import-Module ..\..\Plaster\Plaster.psd1
Invoke-Plaster -TemplatePath .\plasterManifest.json -DestinationPath ..\Out
```

### Interactive vs Non-Interactive Usage

Both formats support the same interactive prompting. If you run either command a second time, you'll see Plaster's file conflict handling. You can use the `-Force` parameter to automatically overwrite existing files.

You can bypass interactive prompting by providing parameters directly to `Invoke-Plaster`. Template parameters are added as dynamic parameters with autocompletion support:

```powershell
$PlasterParams = @{
    TemplatePath = $PWD  # Works with either XML or JSON manifest
    DestinationPath = '..\Out'
    ModuleName = 'FooUtils'
    ModuleDesc = 'Commands for Foo'
    FullName = 'John Q. Doe'
    Email = 'john.q.doe@example.org'
    Version = '1.2.0'
    Options = 'Git','PSake','Pester'
    Editor = 'VSCode'
    License = 'MIT'
}

Invoke-Plaster @PlasterParams -Force
```

## Format Comparison

### XML Format Features
- Backwards compatible with Plaster 1.x
- Well-established syntax
- XML schema validation
- Requires XML escaping for special characters

### JSON Format Features (New in 2.0)
- Modern, readable syntax
- Better tooling support (VS Code IntelliSense)
- JSON schema validation
- Simplified variable syntax: `${ParameterName}` instead of `${PLASTER_PARAM_ParameterName}`
- Easier to work with arrays and objects
- No XML escaping required

## Variable Syntax Differences

**XML Format:**
```xml
<file source='Module.psm1' destination='src\${PLASTER_PARAM_ModuleName}.psm1'/>
<parameter name='Options' type='multichoice' default='0,1,3'>
```

**JSON Format:**
```json
{
  "type": "file",
  "source": "Module.psm1",
  "destination": "src\\${ModuleName}.psm1"
}
```

Notice how JSON format uses simplified variable names (`${ModuleName}` vs `${PLASTER_PARAM_ModuleName}`) and doesn't require XML entity escaping.

## Available Examples

### Main Examples
- **NewModuleTemplate** (`examples/`) - Full-featured module template with both XML and JSON formats
- **NewModule** (`examples/NewModule/`) - Simplified module template
- **NewDscResourceScript** (`examples/NewDscResourceScript/`) - DSC resource template

### Template Validation Examples
- **plasterManifest-validatePattern.xml/json** - Shows input validation patterns

### Localization Examples
- **plasterManifest_fr-FR.xml/json** - French localized version

### Module Extension Examples
- **TemplateModule** (`examples/TemplateModule/`) - Shows how to embed templates in PowerShell modules

## Migration from XML to JSON

Plaster 2.0 includes automatic conversion capabilities:

```powershell
# Convert existing XML manifest to JSON
$xmlPath = ".\plasterManifest.xml"
$jsonPath = ".\plasterManifest.json"
$manifest = Test-PlasterManifest -Path $xmlPath
ConvertTo-JsonManifest -InputObject $manifest -OutputPath $jsonPath
```

## Template Discovery

Both formats are discovered automatically by `Get-PlasterTemplate`:

```powershell
# Shows both XML and JSON templates
Get-PlasterTemplate -Path . -Recurse
Get-PlasterTemplate -IncludeInstalledModules
```

## Creating New Manifests

```powershell
# Create XML manifest (traditional)
New-PlasterManifest -TemplateName "MyTemplate" -TemplateType Project

# Create JSON manifest (Plaster 2.0+)
New-PlasterManifest -TemplateName "MyTemplate" -TemplateType Project -Format JSON

# Convert existing XML to JSON
New-PlasterManifest -TemplateName "MyTemplate" -TemplateType Project -ConvertFromXml
```

## Best Practices

1. **New Templates**: Use JSON format for better tooling and readability
2. **Existing Templates**: XML format continues to work; migrate when convenient
3. **Mixed Environments**: Templates can include both formats for maximum compatibility
4. **Schema Validation**: Both formats support schema validation for better authoring experience
5. **Localization**: Both formats support culture-specific manifests (e.g., `plasterManifest_fr-FR.json`)

For more information about creating manifests, see the help topics:
- `Get-Help about_Plaster_CreatingAManifest`
- `Get-Help about_Plaster_CreatingJsonManifest` (New in 2.0)
- `Get-Help New-PlasterManifest`
