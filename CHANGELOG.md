# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0] - 2026-04-07

### Major Release - Plaster 2.0

This is a major release that modernizes Plaster for PowerShell 7.x while
maintaining full backward compatibility with existing templates and workflows.

### BREAKING CHANGES

- **Minimum PowerShell Version**: Updated from 3.0 to 5.1
- **Test Framework**: Updated to Pester 5.x (breaking change for test authors)
- **Default Encoding**: Changed from 'Default' to 'UTF8-NoBOM' for better
  cross-platform compatibility

### NEW FEATURES

#### PowerShell 7.x Full Support

- **Cross-Platform Compatibility**: Full support for Windows, Linux, and macOS
- **PowerShell Core Optimization**: Improved performance and reliability on
  PowerShell 7.x
- **Platform Detection**: Enhanced platform-specific functionality and path
  handling

#### Modern Development Practices

- **Enhanced Error Handling**: Comprehensive error handling with detailed
  logging
- **Parameter Validation**: Modern PowerShell parameter validation attributes
- **Type Safety**: Improved type safety using PowerShell classes and `using`
  statements
- **Logging System**: Built-in logging system with configurable levels

#### Build and Development

- **Modern Build System**: PowerShellBuild/psake-based build system with compiled module support
- **Pester 5.x Support**: Updated test framework with modern Pester 5.x syntax
- **Cross-Platform CI/CD**: GitHub Actions workflow supporting all platforms
- **Code Coverage**: Integrated code coverage reporting with configurable
  thresholds
- **Static Analysis**: Enhanced PSScriptAnalyzer integration with modern rules

### IMPROVEMENTS

#### Performance

- **Faster Module Loading**: Optimized module loading and reduced startup time
- **Memory Usage**: Improved memory usage and garbage collection
- **Template Processing**: Enhanced template processing performance on large
  projects
- **Cross-Platform I/O**: Optimized file operations for different platforms

#### Developer Experience

- **Better Error Messages**: More descriptive error messages with actionable
  guidance
- **Enhanced Debugging**: Improved debug output and verbose logging
- **IntelliSense Support**: Better parameter completion and help text
- **Modern PowerShell Features**: Leverages PowerShell 5.1+ and 7.x features

#### Cross-Platform Enhancements

- **Path Normalization**: Automatic path separator handling across platforms
- **Encoding Handling**: Consistent UTF-8 encoding with BOM handling
- **Platform-Specific Defaults**: Smart defaults based on operating system
- **Line Ending Normalization**: Proper handling of different line ending styles

### BUG FIXES

#### Core Issues

- **XML Schema Validation**: Fixed .NET Core XML schema validation issues
  ([#107](https://github.com/PowerShellOrg/Plaster/issues/107))
- **Constrained Runspace**: Resolved PowerShell 7.x constrained runspace
  compatibility
- **Path Resolution**: Fixed absolute vs relative path handling across platforms
- **Parameter Store**: Corrected parameter default value storage on non-Windows
  platforms

#### Template Processing

- **Variable Substitution**: Fixed edge cases in parameter substitution
- **Conditional Logic**: Improved reliability of condition evaluation
- **File Encoding**: Resolved encoding issues with template files
- **Directory Creation**: Fixed recursive directory creation on Unix systems

#### Module Loading

- **Import Errors**: Resolved module import issues on PowerShell Core
- **Dependency Resolution**: Fixed module dependency loading order
- **Resource Loading**: Improved localized resource loading reliability

### MIGRATION GUIDE

#### For Template Authors

1. **No Changes Required**: Existing XML templates work without modification
2. **Encoding**: Consider updating templates to use UTF-8 encoding
3. **Testing**: Update any custom tests to use Pester 5.x syntax

#### For Template Users

1. **PowerShell Version**: Ensure PowerShell 5.1 or higher is installed
2. **Module Update**: Use `Update-Module Plaster` to get version 2.0
3. **Workflows**: No changes required to existing Invoke-Plaster usage

#### For Contributors

1. **Build System**: Use `./build.ps1` instead of psake commands
2. **Tests**: Update to Pester 5.x syntax and configuration
3. **Development**: Follow new coding standards and use modern PowerShell
   features

### INTERNAL CHANGES

#### Code Quality

- **PSScriptAnalyzer**: Updated to latest rules and best practices
- **Code Coverage**: Achieved >80% code coverage across all modules
- **Documentation**: Comprehensive inline documentation and examples
- **Type Safety**: Added parameter validation and type constraints

#### Architecture

- **Module Structure**: Reorganized for better maintainability
- **Error Handling**: Centralized error handling and logging
- **Resource Management**: Improved resource cleanup and disposal
- **Platform Abstraction**: Abstracted platform-specific functionality

#### Testing

- **Test Coverage**: Comprehensive test suite covering all platforms
- **Integration Tests**: Added end-to-end integration testing
- **Performance Tests**: Benchmarking for performance regression detection
- **Cross-Platform Tests**: Automated testing on Windows, Linux, and macOS

### ACKNOWLEDGMENTS

Special thanks to the PowerShell community for their patience during the
transition and to all contributors who helped modernize Plaster for the
PowerShell 7.x era.

### COMPATIBILITY MATRIX

| PowerShell Version | Windows | Linux | macOS | Status              |
|--------------------|---------|-------|-------|---------------------|
| 5.1 (Desktop)      | ✅      | ❌    | ❌   | Fully Supported     |
| 7.0+ (Core)        | ✅      | ✅    | ✅   | Fully Supported     |
| 3.0-5.0            | ❌      | ❌    | ❌   | No Longer Supported |

---

## 1.1.4 - (Unreleased - Legacy)

### Fixed

- Write destination path with Write-Host so it doesn't add extra output when
  -PassThru specified [#326](https://github.com/PowerShell/Plaster/issues/326).

### Changed

- Updated PSScriptAnalyzerSettings.psd1 template file to sync w/latest in
  vscode-powershell examples.
- Text parameter with default value where condition evaluates to false returns
  default value.

## 1.1.1 - 2017-10-26

### Fixed

- Added $IsMacOS variable to constrained runspace
  [#291](https://github.com/PowerShell/Plaster/issues/291).
- Added missing .cat file from 1.1.0 release
  [#292](https://github.com/PowerShell/Plaster/issues/292).

## 1.1.0 - 2017-10-25

### Fixed

- Fixed prompt errors when prompt text null or empty
  [#236](https://github.com/PowerShell/Plaster/issues/236).
- Fixed New Module Script template's Test task which fails to run on x64 Visual
  Studio Code.
- Fixed Test-PlasterManifest on non-Windows running .NET Core 2.0 failed with
  path using \ instead of /. Thanks to
  [@elmundio87](https://github.com/elmundio87) via PR
  [#282](https://github.com/PowerShell/Plaster/pull/282)

### Added

- Added constrained runspace cmdlet: Out-String
  [#235](https://github.com/PowerShell/Plaster/issues/236).
- Added constrained runspace variables: PSVersionTable and on >= PS v6 IsLinux,
  IsOSX and IsWindows [#239](https://github.com/PowerShell/Plaster/issues/239).
- The parameter element now supports a condition attribute so that prompting for
  parameters can be conditional based on environmental factors (such as OS) or
  answers to previous parameter prompts. This allows template authors to build a
  "dynamic" set of prompts.
- Added constrained runspace cmdlet: Compare-Object
  [#286](https://github.com/PowerShell/Plaster/issues/287).

### Changed

- Simplified New Module Script template user choices i.e. removed prompt for
  adding Pester test. The test is now always added.

## 1.0.1 - 2016-12-16

- Fixed issue with the used of `GetModule -FullyQualifiedName` on PowerShell v3

## 1.0.0 - 2016-12-16

- First official release shipped to the PowerShell Gallery!

## 0.3.0 - 2016-11-05

- Updated build script with support for building help from markdown files,
  building updatable help files and generating file catalog.
- Initial release shows the basics of what this module could do.

## 0.2.0 - 2016-07-31

- Introduced new directive `<templateFile>` that implicitlys expands the
  specified file(s), allowing the template author to set the target file
  encoding. This new directive supports a wildcard source specifier like the
  `<file>` directive. With this change, `<file>` no longer supports template
  expansion and as result the `template` and `encoding` attributes have been
  removed.
- Restructured the module source to follow best practice of separating
  infrastructure from module files.
- Fixed #47: How to create empty directories. The `<file>` directive supports
  this now.
- Fixed #58: File recurse does not work anymore.
