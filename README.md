# Plaster 2.0

![Build Status](https://img.shields.io/github/actions/workflow/status/PowerShellOrg/Plaster/ci.yml?branch=master)
![PowerShell Gallery](https://img.shields.io/powershellgallery/v/Plaster?logo=powershell)
![Platform Support](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![PowerShell Support](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207.x-blue)

> **Plaster 2.0 is here!** Fully modernized for PowerShell 7.x with complete cross-platform support while maintaining 100% backward compatibility with existing templates.

## What's New in 2.0

- **Full Cross-Platform Support**: Windows, Linux, and macOS
- **PowerShell 7.x Optimized**: Enhanced performance and reliability
- **Modern Build System**: InvokeBuild with comprehensive CI/CD
- **Pester 5.x Integration**: Modern testing framework
- **Better Package Management**: Enhanced module distribution
- **Improved Security**: Enhanced validation and error handling

## Overview

Plaster is a template-based file and project generator written in PowerShell. Its purpose is to streamline the creation of PowerShell module projects, Pester tests, DSC configurations, and more. File generation is performed using crafted templates which allow users to fill in details and choose from options to get their desired output.

Think of Plaster as [Yeoman](http://yeoman.io) for the PowerShell community.

## Key Features

### Template-Based Generation
- **Flexible Templates**: Create files, directories, and entire project structures
- **Parameter Substitution**: Dynamic content based on user input
- **Conditional Logic**: Smart templates that adapt based on choices
- **Localization Support**: Multi-language template support

### Cross-Platform Ready
- **Universal Compatibility**: Works on Windows, Linux, and macOS
- **Path Normalization**: Automatic handling of platform-specific paths
- **Encoding Support**: UTF-8 with proper BOM handling
- **Line Ending Management**: Consistent line endings across platforms

### Developer Friendly
- **Modern PowerShell**: Leverages PowerShell 5.1+ and 7.x features
- **Rich Validation**: Comprehensive parameter and template validation
- **Detailed Logging**: Configurable logging for debugging and monitoring
- **IntelliSense Support**: Enhanced tab completion and help

## Installation

### PowerShell Gallery (Recommended)
```powershell
# Install for current user
Install-Module Plaster -Scope CurrentUser

# Install globally (requires admin)
Install-Module Plaster -Scope AllUsers

# Update from v1.x
Update-Module Plaster
```

### Manual Installation
Download the latest release from our [Releases](https://github.com/PowerShellOrg/Plaster/releases) page.

### Development Version
```powershell
# Clone and build from source
git clone https://github.com/PowerShellOrg/Plaster.git
cd Plaster
./build.ps1
```

## Quick Start

### 1. Explore Available Templates
```powershell
# List built-in templates
Get-PlasterTemplate

# Include templates from installed modules
Get-PlasterTemplate -IncludeInstalledModules

# Search for specific templates
Get-PlasterTemplate -Name "*Module*" -Tag "PowerShell"
```

### 2. Create a New Project
```powershell
# Interactive mode - Plaster will prompt for parameters
Invoke-Plaster -TemplatePath BuiltinTemplate -DestinationPath C:\MyNewProject

# Non-interactive mode - provide all parameters
$templateParams = @{
    TemplatePath    = 'BuiltinTemplate'
    DestinationPath = 'C:\MyNewProject'
    ModuleName      = 'MyAwesomeModule'
    ModuleAuthor    = 'Your Name'
    ModuleVersion   = '1.0.0'
}
Invoke-Plaster @templateParams
```

### 3. Create Your Own Template
```powershell
# Generate a new template manifest
New-PlasterManifest -TemplateName 'MyTemplate' -TemplateType 'Project'

# Test your template
Test-PlasterManifest -Path .\plasterManifest.xml
```

## Documentation

### Core Documentation
- **[Getting Started Guide](docs/en-US/about_Plaster.help.md)** - Learn the basics
- **[Creating Templates](docs/en-US/about_Plaster_CreatingAManifest.help.md)** - Template authoring guide
- **[Cmdlet Reference](docs/en-US/Plaster.md)** - Complete API documentation
- **[Migration Guide](docs/Migration-v2.md)** - Upgrading from v1.x

### Learning Resources
- **[Template Gallery](docs/Templates.md)** - Community templates
- **[Best Practices](docs/BestPractices.md)** - Template design guidelines
- **[Examples](examples/)** - Sample templates and usage
- **[FAQ](docs/FAQ.md)** - Common questions and answers

### Video Resources
- [Working with Plaster Presentation](https://youtu.be/16CYGTKH73U) by David Christian

### Blog Posts
- [Working with Plaster](http://overpoweredshell.com/Working-with-Plaster/) by David Christian

## Template Structure

A Plaster template consists of:

```
MyTemplate/
├── plasterManifest.xml    # Template definition
├── template files/        # Files to be copied/processed
└── assets/               # Additional resources
```

### Basic Manifest Example
```xml
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest schemaVersion="1.2" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
    <metadata>
        <n>MyTemplate</n>
        <id>12345678-1234-1234-1234-123456789012</id>
        <version>1.0.0</version>
        <title>My Custom Template</title>
        <description>A template for creating awesome projects</description>
        <author>Your Name</author>
        <tags>PowerShell, Module</tags>
    </metadata>
    <parameters>
        <parameter name="ProjectName" type="text" prompt="Enter project name"/>
        <parameter name="IncludeTests" type="choice" prompt="Include tests?">
            <choice label="&amp;Yes" help="Include Pester tests" value="Yes"/>
            <choice label="&amp;No" help="Skip tests" value="No"/>
        </parameter>
    </parameters>
    <content>
        <file source="template.ps1" destination="${ProjectName}.ps1"/>
        <templateFile source="README.md" destination="README.md"/>
    </content>
</plasterManifest>
```

## Usage Examples

### Creating a PowerShell Module
```powershell
# Use the built-in module template
$moduleParams = @{
    TemplatePath      = (Get-PlasterTemplate | Where-Object Name -eq 'NewPowerShellScriptModule').TemplatePath
    DestinationPath   = 'C:\Dev\MyModule'
    ModuleName        = 'MyModule'
    ModuleAuthor      = 'John Doe'
    ModuleDescription = 'An awesome PowerShell module'
    ModuleVersion     = '0.1.0'
}
Invoke-Plaster @moduleParams
```

### Creating a Custom Script
```powershell
# Create a new script from template
Invoke-Plaster -TemplatePath .\MyScriptTemplate -DestinationPath .\Scripts -ScriptName 'ProcessData' -Author 'Jane Smith'
```

### Batch Project Creation
```powershell
# Create multiple projects from a template
$projects = @('ProjectA', 'ProjectB', 'ProjectC')
foreach ($project in $projects) {
    Invoke-Plaster -TemplatePath .\BaseTemplate -DestinationPath ".\$project" -ProjectName $project
}
```

## Development and Testing

### Prerequisites
- PowerShell 5.1 or higher
- Pester 5.0+ (for testing)
- PSScriptAnalyzer (for code quality)
- InvokeBuild (for building)

### Building from Source
```powershell
# Clone the repository
git clone https://github.com/PowerShellOrg/Plaster.git
cd Plaster

# Install build dependencies
./build.ps1 -Task Bootstrap

# Build the module
./build.ps1 -Task Build

# Run tests
./build.ps1 -Task Test

# Full build pipeline
./build.ps1 -Task Pipeline
```

### Running Tests
```powershell
# Run all tests
Invoke-Pester

# Run specific test categories
Invoke-Pester -Tag Unit
Invoke-Pester -Tag Integration
Invoke-Pester -Tag CrossPlatform

# Run with code coverage
Invoke-Pester -CodeCoverage
```

## Cross-Platform Support

Plaster 2.0 provides full cross-platform support:

| Feature | Windows | Linux | macOS | Notes |
|---------|---------|-------|-------|-------|
| Core Functionality | ✅ | ✅ | ✅ | All features work |
| Path Handling | ✅ | ✅ | ✅ | Automatic normalization |
| File Encoding | ✅ | ✅ | ✅ | UTF-8 with BOM support |
| Parameter Store | ✅ | ✅ | ✅ | Platform-specific locations |
| XML Schema Validation | ✅ | ⚠️ | ⚠️ | Limited on non-Windows |

### Platform-Specific Considerations

#### Windows
- Full XML schema validation support
- Uses `$env:LOCALAPPDATA\Plaster` for parameter storage

#### Linux
- Uses `$HOME/.local/share/plaster` for parameter storage
- Follows XDG Base Directory Specification

#### macOS
- Uses `$HOME/.plaster` for parameter storage
- Full Unicode support for file names

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Ways to Contribute
- **Report Bugs** - File issues with detailed reproduction steps
- **Suggest Features** - Share ideas for new functionality
- **Improve Documentation** - Help make our docs better
- **Submit Pull Requests** - Fix bugs or add features
- **Create Templates** - Share useful templates with the community

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Compatibility

### PowerShell Versions
- ✅ **PowerShell 5.1** (Windows PowerShell)
- ✅ **PowerShell 7.0+** (Cross-platform)
- ❌ **PowerShell 3.0-5.0** (No longer supported)

### Breaking Changes from v1.x
- Minimum PowerShell version increased to 5.1
- Default encoding changed to UTF8-NoBOM
- Pester 5.x required for development/testing
- Some internal APIs changed (public APIs remain compatible)

## Support

### Getting Help
- **Documentation** - Check our comprehensive docs
- **Discussions** - Ask questions in [GitHub Discussions](https://github.com/PowerShellOrg/Plaster/discussions)
- **Issues** - Report bugs in [GitHub Issues](https://github.com/PowerShellOrg/Plaster/issues)
- **Community** - Join the PowerShell community on [Discord](https://discord.gg/powershell)

### Commercial Support
For enterprise support and consulting, contact the maintainers through GitHub.

## License

This project is licensed under the [MIT License](LICENSE) - see the license file for details.

## Acknowledgments

### Maintainers
- [Jeff Hicks](https://github.com/jdhitsolutions) - [@jeffhicks](http://twitter.com/jeffhicks)
- [James Petty](https://github.com/psjamess) - [@PSJamesP](http://twitter.com/PSJamesP)

### Contributors
Special thanks to all the community contributors who have helped make Plaster better. See our [Contributors](https://github.com/PowerShellOrg/Plaster/contributors) page for the full list.

### Legacy
Originally created by the PowerShell team at Microsoft and transferred to PowerShell.org in 2020 to ensure continued community development.

---

**Made with ❤️ by the PowerShell Community**

[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/Plaster)](https://www.powershellgallery.com/packages/Plaster/)
[![GitHub stars](https://img.shields.io/github/stars/PowerShellOrg/Plaster)](https://github.com/PowerShellOrg/Plaster/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/PowerShellOrg/Plaster)](https://github.com/PowerShellOrg/Plaster/network/members)