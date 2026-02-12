# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.0-alpha1] 2026-02-12

### Fixed

- Null-coalescing operators replaced with PS5.1-compatible syntax in
  Write-PlasterLog to fix PowerShell 5.1 compatibility
  ([#442](https://github.com/PowerShellOrg/Plaster/issues/442))

## [2.0.0-alpha] 2025-06-18

### Added

- Cross-platform compatibility with full support for Windows, Linux, and macOS
- PowerShell 7.x optimization with improved performance and reliability
- Enhanced error handling with comprehensive error handling and detailed logging
- Modern PowerShell parameter validation attributes and type safety
- Built-in logging system with configurable levels
- Modern InvokeBuild-based build system replacing legacy psake
- Pester 5.x support with updated test framework syntax
- Cross-platform CI/CD with GitHub Actions workflow supporting all platforms
- Integrated code coverage reporting with configurable thresholds
- Enhanced PSScriptAnalyzer integration with modern rules
- Parameter element now supports a condition attribute for conditional prompting
- Better error messages with actionable guidance
- Improved debug output and verbose logging
- Better IntelliSense support with improved parameter completion and help text
- Automatic path separator handling across platforms
- Consistent UTF-8 encoding with BOM handling across platforms
- Platform-specific defaults based on operating system
- Proper handling of different line ending styles
- Comprehensive test suite covering all platforms with integration and
  performance tests
- Automated testing on Windows, Linux, and macOS

### Changed

- Minimum PowerShell version updated from 3.0 to 5.1
- Default encoding changed from 'Default' to 'UTF-8-NoBOM' for better
  cross-platform compatibility
- Test framework updated to Pester 5.x (breaking change for test authors)
- Module structure reorganized for better maintainability
- Error handling centralized with improved logging
- Platform-specific functionality abstracted for better cross-platform support
- Optimized module loading and reduced startup time
- Improved memory usage and garbage collection
- Enhanced template processing performance on large projects
- Improved file operations for different platforms
- Better parameter completion and help text

### Fixed

- XML schema validation issues on .NET Core
  ([#107](https://github.com/PowerShellOrg/Plaster/issues/107))
- PowerShell 7.x constrained runspace compatibility issues
- Absolute vs relative path handling across platforms
- Parameter default value storage on non-Windows platforms
- Edge cases in parameter substitution
- Condition evaluation reliability
- Template file encoding issues
- Recursive directory creation on Unix systems
- Module import issues on PowerShell Core
- Module dependency loading order
- Localized resource loading reliability

## [1.1.4] Unreleased

### Added

- None

### Changed

- Updated PSScriptAnalyzerSettings.psd1 template file to sync with latest in
  vscode-powershell examples
- Text parameter with default value where condition evaluates to false now
  returns default value

### Fixed

- Write destination path with Write-Host so it doesn't add extra output when
  -PassThru specified [#326](https://github.com/PowerShell/Plaster/issues/326)

## [1.1.1] 2017-10-26

### Fixed

- Added $IsMacOS variable to constrained runspace
  [#291](https://github.com/PowerShell/Plaster/issues/291)
- Added missing .cat file from 1.1.0 release
  [#292](https://github.com/PowerShell/Plaster/issues/292)

## [1.1.0] 2017-10-25

### Added

- Constrained runspace cmdlet: Out-String
  [#235](https://github.com/PowerShell/Plaster/issues/236)
- Constrained runspace variables: PSVersionTable and on >= PS v6 IsLinux,
  IsOSX and IsWindows [#239](https://github.com/PowerShell/Plaster/issues/239)
- Parameter element now supports a condition attribute so that prompting for
  parameters can be conditional based on environmental factors (such as OS) or
  answers to previous parameter prompts. This allows template authors to build a
  "dynamic" set of prompts
- Constrained runspace cmdlet: Compare-Object
  [#286](https://github.com/PowerShell/Plaster/issues/287)

### Changed

- Simplified New Module Script template user choices (removed prompt for adding
  Pester test; the test is now always added)

### Fixed

- Fixed prompt errors when prompt text is null or empty
  [#236](https://github.com/PowerShell/Plaster/issues/236)
- Fixed New Module Script template's Test task which fails to run on x64 Visual
  Studio Code
- Fixed Test-PlasterManifest on non-Windows running .NET Core 2.0 which failed
  with path using \ instead of /. Thanks to
  [@elmundio87](https://github.com/elmundio87) via PR
  [#282](https://github.com/PowerShell/Plaster/pull/282)

## [1.0.1] 2016-12-16

### Fixed

- Fixed issue with the use of `GetModule -FullyQualifiedName` on PowerShell v3

## [1.0.0] 2016-12-16

### Added

- First official release shipped to the PowerShell Gallery

## [0.3.0] 2016-11-05

### Added

- Build script with support for building help from markdown files, building
  updatable help files and generating file catalog

## [0.2.0] 2016-07-31

### Added

- New directive `<templateFile>` that implicitly expands the specified file(s),
  allowing the template author to set the target file encoding. This new
  directive supports a wildcard source specifier like the `<file>` directive

### Changed

- `<file>` directive no longer supports template expansion
- Removed `template` and `encoding` attributes from `<file>` directive
- Restructured the module source to follow best practice of separating
  infrastructure from module files

### Fixed

- How to create empty directories: the `<file>` directive supports this now
  ([#47](https://github.com/PowerShell/Plaster/issues/47))
- File recurse does not work anymore
  ([#58](https://github.com/PowerShell/Plaster/issues/58))
