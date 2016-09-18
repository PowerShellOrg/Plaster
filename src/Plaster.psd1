# DO NOT COPY THIS MANIFEST VERBATIM.  THIS IS JUST A SAMPLE.
# GENERATE YOUR MANIFEST USING THE New-ManifestModule COMMAND TO
# GUARANTEE YOU GET A UNIQUE GUID FOR YOUR MODULE.
@{
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
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

        } # End of PSData hashtable

    } # End of PrivateData hashtable

# Script module or binary module file associated with this manifest.
RootModule = 'Plaster.psm1'

# Version number of this module.
ModuleVersion = '0.2.0'

# ID used to uniquely identify this module
GUID = 'cfce3c5e-402f-412a-a83a-7b7ee9832ff4'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) Microsoft Corporation 2016. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Plaster scaffolds PowerShell projects and files.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

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
FunctionsToExport = @(
    'Invoke-Plaster'
    'New-PlasterManifest'
    'Test-PlasterManifest'
    )

# Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = '*'

# Aliases to export from this module
# AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
