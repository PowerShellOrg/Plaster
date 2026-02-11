@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Plaster.psm1'

    # ID used to uniquely identify this module
    GUID = 'cfce3c5e-402f-412a-a83a-7b7ee9832ff4'

    # Version number of this module.
    ModuleVersion = '2.0.0-beta1'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a
    # PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Plaster', 'CodeGenerator', 'Scaffold', 'Template', 'JSON', 'PowerShell7')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/PowerShellOrg/Plaster/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/PowerShellOrg/Plaster'

            # A URL to an icon representing this module.
            #IconUri = 'https://github.com/PowerShell/Plaster/icon.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/PowerShellOrg/Plaster/blob/master/CHANGELOG.md'
        }
    }

    # Author of this module
    Author = 'PowerShell.org'

    # Company or vendor of this module
    CompanyName = 'PowerShell.org'

    # Copyright statement for this module
    Copyright = '(c) PowerShell.org 2016-2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Plaster is a template-based file and project generator written in PowerShell. Create consistent PowerShell projects with customizable templates supporting both XML and JSON formats.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module - explicitly list each function that should be
    # exported.  This improves performance of PowerShell when discovering the commands in
    # module.
    FunctionsToExport = '*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = '*'

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/PowerShellOrg/Plaster/tree/master/docs'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
