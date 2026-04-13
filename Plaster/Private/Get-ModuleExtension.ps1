function Get-ModuleExtension {
    <#
    .SYNOPSIS
    Retrieves module extensions based on specified criteria.

    .DESCRIPTION
    This function retrieves module extensions that match the specified module
    name and version criteria.

    .PARAMETER ModuleName
    The name of the module to retrieve extensions for.

    .PARAMETER ModuleVersion
    The version of the module to retrieve extensions for.

    .PARAMETER ListAvailable
    Indicates whether to list all available modules or only the the latest
    version of each module.

    .EXAMPLE
    Get-ModuleExtension -ModuleName "MyModule" -ModuleVersion "1.0.0"

    Retrieves extensions for the module "MyModule" with version "1.0.0".
    .NOTES

    #>
    [CmdletBinding()]
    param(
        [string]
        $ModuleName,

        [Version]
        $ModuleVersion,

        [Switch]
        $ListAvailable
    )

    # Only get the latest version of each module
    $modules = Get-Module -ListAvailable
    if (!$ListAvailable.IsPresent) {
        $modules = $modules |
            Group-Object Name |
            ForEach-Object {
                $_.group |
                    Sort-Object Version |
                    Select-Object -Last 1
                }
    }

    Write-Verbose "Found $($modules.Length) installed modules to scan for extensions."

    foreach ($module in $modules) {
        if ($module.PrivateData -and
            $module.PrivateData.PSData -and
            $module.PrivateData.PSData.Extensions) {

            Write-Verbose "Found module with extensions: $($module.Name)"

            foreach ($extension in $module.PrivateData.PSData.Extensions) {

                Write-Verbose "Comparing against module extension: $($extension.Module)"

                if ([String]::IsNullOrEmpty($extension.MinimumVersion)) {
                    # Fill with a default value if not specified
                    $minimumVersion = $null
                } else {
                    $minimumVersion = Resolve-ModuleVersionString $extension.MinimumVersion
                }
                if ([String]::IsNullOrEmpty($extension.MaximumVersion)) {
                    # Fill with a default value if not specified
                    $maximumVersion = $null
                } else {
                    $maximumVersion = Resolve-ModuleVersionString $extension.MaximumVersion
                }

                if (($extension.Module -eq $ModuleName) -and
                    (!$minimumVersion -or $ModuleVersion -ge $minimumVersion) -and
                    (!$maximumVersion -or $ModuleVersion -le $maximumVersion)) {
                    # Return a new object with the extension information
                    [PSCustomObject]@{
                        Module = $module
                        MinimumVersion = $minimumVersion
                        MaximumVersion = $maximumVersion
                        Details = $extension.Details
                    }
                }
            }
        }
    }
}
