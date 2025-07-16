function Get-PlasterTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0,
            ParameterSetName = "Path",
            HelpMessage = "Specifies a path to a folder containing a Plaster template or multiple template folders.  Can also be a path to plasterManifest.xml.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Position = 1,
            ParameterSetName = "Path",
            HelpMessage = "Will return templates that match the name.")]
        [Parameter(Position = 1,
            ParameterSetName = "IncludedTemplates",
            HelpMessage = "Will return templates that match the name.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name = "*",

        [Parameter(ParameterSetName = "Path",
            HelpMessage = "Will return templates that match the tag.")]
        [Parameter(ParameterSetName = "IncludedTemplates",
            HelpMessage = "Will return templates that match the tag.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Tag = "*",

        [Parameter(ParameterSetName = "Path",
            HelpMessage = "Indicates that this cmdlet gets the items in the specified locations and in all child items of the locations.")]
        [switch]
        $Recurse,

        [Parameter(Position = 0,
            Mandatory = $true,
            ParameterSetName = "IncludedTemplates",
            HelpMessage = "Initiates a search for latest version Plaster templates inside of installed modules.")]
        [switch]
        [Alias("IncludeModules")]
        $IncludeInstalledModules,

        [Parameter(ParameterSetName = "IncludedTemplates",
            HelpMessage = "If specified, searches for Plaster templates inside of all installed module versions.")]
        [switch]
        $ListAvailable
    )

    process {
        if ($Path) {
            # Is this a folder path or a Plaster manifest file path?
            if (!$Recurse.IsPresent) {
                if (Test-Path $Path -PathType Container) {
                    $Path = Resolve-Path "$Path/plasterManifest.xml"
                }

                # Use Test-PlasterManifest to load the manifest file
                Write-Verbose "Attempting to get Plaster template at path: $Path"
                $newTemplateObjectFromManifestSplat = @{
                    ManifestPath = $Path
                    Name = $Name
                    Tag = $Tag
                }
                New-TemplateObjectFromManifest @newTemplateObjectFromManifestSplat
            } else {
                Write-Verbose "Attempting to get Plaster templates recursively under path: $Path"
                $getManifestsUnderPathSplat = @{
                    RootPath = $Path
                    Recurse = $Recurse.IsPresent
                    Name = $Name
                    Tag = $Tag
                }
                Get-ManifestsUnderPath @getManifestsUnderPathSplat
            }
        } else {
            # Return all templates included with Plaster
            $getManifestsUnderPathSplat = @{
                RootPath = "$PSScriptRoot\Templates"
                Recurse = $true
                Name = $Name
                Tag = $Tag
            }
            Get-ManifestsUnderPath @getManifestsUnderPathSplat

            if ($IncludeInstalledModules.IsPresent) {
                # Search for templates in module path
                $GetModuleExtensionParams = @{
                    ModuleName = "Plaster"
                    ModuleVersion = $PlasterVersion
                    ListAvailable = $ListAvailable
                }
                $extensions = Get-ModuleExtension @GetModuleExtensionParams

                foreach ($extension in $extensions) {
                    # Scan all module paths registered in the module
                    foreach ($templatePath in $extension.Details.TemplatePaths) {
                        $expandedTemplatePath =
                        [System.IO.Path]::Combine(
                            $extension.Module.ModuleBase,
                            $templatePath,
                            "plasterManifest.xml")

                        $newTemplateObjectFromManifestSplat = @{
                            ManifestPath = $expandedTemplatePath
                            Name = $Name
                            Tag = $Tag
                            ErrorAction = 'SilentlyContinue'
                        }
                        New-TemplateObjectFromManifest @newTemplateObjectFromManifestSplat
                    }
                }
            }
        }
    }
}
