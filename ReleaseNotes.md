## What is New in Plaster 2.0.0
April 2026

### Breaking Changes
- Minimum PowerShell version updated to 5.1 (was 3.0)
- Test framework updated to Pester 5.x
- Default file encoding changed to UTF8-NoBOM

### New Features
- **JSON Manifest Support**: Create templates using JSON (`plasterManifest.json`) with full JSON Schema validation and VS Code IntelliSense
- **Cross-Platform**: Full support for Windows, Linux, and macOS on PowerShell 7.x
- **Simplified Variables**: JSON manifests use `${ParameterName}` instead of `${PLASTER_PARAM_ParameterName}`
- **Native Arrays**: Multichoice defaults use JSON arrays `[0, 1, 2]` instead of comma-separated strings
- **Format Auto-Detection**: Plaster automatically detects and processes both XML and JSON manifests
- **Enhanced Logging**: Configurable logging via `$env:PLASTER_LOG_LEVEL`

### Improvements
- Better error messages with actionable guidance
- Improved constrained runspace compatibility with PowerShell 7.x
- Platform-specific parameter store paths (XDG on Linux, standard paths on macOS/Windows)
- Optimized module loading and template processing
- Comprehensive Pester 5.x test suite

### Bug Fixes
- Fixed .NET Core XML schema validation issues
- Resolved path handling on non-Windows platforms
- Fixed constrained runspace compatibility with PowerShell 7.x
- Corrected parameter default value storage on non-Windows platforms
- Fixed variable substitution edge cases

### Feedback
Please send your feedback to https://github.com/PowerShellOrg/Plaster/issues
