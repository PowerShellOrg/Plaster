. $PSScriptRoot\GetModuleExtension.ps1

function Get-PlasterTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,
                   ParameterSetName="Path",
                   HelpMessage="Specifies a path to a folder containing a Plaster template or multiple template folders.  Can also be a path to plasterManifest.xml.")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(ParameterSetName="Path",
                   HelpMessage="Indicates that this cmdlet gets the items in the specified locations and in all child items of the locations.")]
        [switch]
        $Recurse,

        [Parameter(Position=0,
                   Mandatory=$true,
                   ParameterSetName="IncludedTemplates",
                   HelpMessage="Initiates a search for Plaster templates inside of installed modules.")]
        [switch]
        [Alias("IncludeModules")]
        $IncludeInstalledModules
    )

    process {
        function CreateTemplateObjectFromManifest([System.IO.FileInfo]$manifestPath) {

            $manifestXml = Test-PlasterManifest -Path $manifestPath
            $metadata = $manifestXml["plasterManifest"]["metadata"]

            $manifestObj = [PSCustomObject]@{
                Title = $metadata["title"].InnerText
                Author = $metadata["author"].InnerText
                Version = New-Object -TypeName "System.Version" -ArgumentList $metadata["version"].InnerText
                Description = $metadata["description"].InnerText
                Tags = $metadata["tags"].InnerText.split(",") | % { $_.Trim() }
                TemplatePath = $manifestPath.Directory.FullName
            }

            $manifestObj.PSTypeNames.Insert(0, "Microsoft.PowerShell.Plaster.PlasterTemplate")
            return $manifestObj
        }

        function GetManifestsUnderPath([string]$rootPath, [bool]$recurse) {
            $manifestPaths = Get-ChildItem -Path $rootPath -Include "plasterManifest.xml" -Recurse:$recurse
            foreach ($manifestPath in $manifestPaths) {
                CreateTemplateObjectFromManifest $manifestPath -ErrorAction SilentlyContinue
            }
        }

        if ($Path) {
            # Is this a folder path or a Plaster manifest file path?
            if (!$Recurse.IsPresent) {
                if (Test-Path $Path -PathType Container) {
                    $Path = Resolve-Path "$Path/plasterManifest.xml"
                }

                # Use Test-PlasterManifest to load the manifest file
                Write-Verbose "Attempting to get Plaster template at path: $Path"
                CreateTemplateObjectFromManifest $Path
            }
            else {
                Write-Verbose "Attempting to get Plaster templates recursively under path: $Path"
                GetManifestsUnderPath $Path $Recurse.IsPresent
            }
        }
        else {
            # Return all templates included with Plaster
            GetManifestsUnderPath "$PSScriptRoot\Templates" $true

            if ($IncludeInstalledModules.IsPresent) {
                # Search for templates in module path
                $extensions = Get-ModuleExtension -ModuleName Plaster -ModuleVersion $PlasterVersion

                foreach ($extension in $extensions) {
                    # Scan all module paths registered in the module
                    foreach ($templatePath in $extension.Details.TemplatePaths) {
                        $expandedTemplatePath =
                            [System.IO.Path]::Combine(
                                $extension.Module.ModuleBase,
                                $templatePath,
                                "plasterManifest.xml")

                        CreateTemplateObjectFromManifest $expandedTemplatePath -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
}