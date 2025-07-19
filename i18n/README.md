# Internationalization (i18n) Files

⚠️ **IMPORTANT: DO NOT EDIT THESE FILES DIRECTLY** ⚠️

## About These Files

The files in this directory contain localized resources for the Plaster
PowerShell module. These files are automatically generated and updated by
[Crowdin](https://crowdin.com/), our localization management platform.

## What's In This Directory

- `*.json` files: Localized string resources for different languages and cultures
- Translation files are named using the format: `Plaster.Resources.<culture-code>.json`

## How Localization Works

1. **Source strings** are maintained in the main codebase
2. **Crowdin** automatically syncs these strings for translation
3. **Translators** use the Crowdin platform to provide translations
4. **Updated translations** are automatically pushed back to this repository
   via Crowdin integration

## Contributing Translations

If you'd like to help translate Plaster:

1. Visit our Crowdin project page
2. Request access to contribute translations
3. Use the Crowdin web interface to submit translations
4. Your contributions will be automatically included in future releases

## For Maintainers

- Never edit the `*.json` files in this directory directly
- Changes to source strings should be made in the main PowerShell code
- The source of truth for necessary strings will be
  `Plaster\en-US\Plaster.Resources.psd1`.
- The `en-US` json file is exported by running the `ExportLocalizationJson`
  build task. i.e. `.\build.ps1 -Task ExportLocalizationJson`
- Crowdin will automatically detect and sync new or modified strings
- The Crowdin integration will create pull requests with updated translations

## Questions?

If you have questions about the localization process, please open an issue
in the main repository.
