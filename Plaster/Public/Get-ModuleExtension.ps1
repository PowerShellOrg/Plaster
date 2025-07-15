function Get-ModuleExtension {
    [CmdletBinding()]
    param(
        [string]
        $ModuleName,

        [Version]
        $ModuleVersion,

        [Switch]
        $ListAvailable
    )

    #Only get the latest version of each module
    $modules = Get-Module -ListAvailable
    if (!$ListAvailable) {
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

                $minimumVersion = Resolve-ModuleVersionString $extension.MinimumVersion
                $maximumVersion = Resolve-ModuleVersionString $extension.MaximumVersion

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
