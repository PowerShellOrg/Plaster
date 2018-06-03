@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Plaster.psm1'

    # ID used to uniquely identify this module
    GUID = 'cfce3c5e-402f-412a-a83a-7b7ee9832ff4'

    # Version number of this module.
    ModuleVersion = '1.1.4'

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a
    # PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Plaster', 'CodeGenerator', 'Scaffold')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/PowerShell/Plaster/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/PowerShell/Plaster'

            # A URL to an icon representing this module.
            #IconUri = 'https://github.com/PowerShell/Plaster/icon.png'

            # ReleaseNotes of this module - our ReleaseNotes are in
            # the file ReleaseNotes.md
            # ReleaseNotes = ''

        }
    }

    # Author of this module
    Author = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright = '(c) Microsoft Corporation 2016-2018. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Plaster scaffolds PowerShell projects and files.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '3.0'

    # Functions to export from this module - explicitly list each function that should be
    # exported.  This improves performance of PowerShell when discovering the commands in
    # module.
    FunctionsToExport = @(
        'Invoke-Plaster'
        'New-PlasterManifest'
        'Get-PlasterTemplate',
        'Test-PlasterManifest'
        )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # HelpInfo URI of this module
    # HelpInfoURI = ''
}
