function Get-ModuleExtension {
    [CmdletBinding()]
    param(
        [string]
        $ModuleName,

        [Version]
        $ModuleVersion
        
        [Switch]
        $AllVersions
    )

    #Only get the latest version of each module
    $modules = Get-Module -ListAvailable 
    if (-not $AllVersions) {
        $modules = $modules | 
            Group-Object Name | 
            Foreach-Object {
                $_.group | 
                    Sort-Object Version | 
                    Select-Object -Last 1
            }
    }
        
    Write-Verbose "`nFound $($modules.Length) installed modules to scan for extensions."

    function ParseVersion($versionString) {
        $parsedVersion = $null

        if ($versionString) {
            # We're targeting Semantic Versioning 2.0 so make sure the version has
            # at least 3 components (X.X.X).  This logic ensures that the "patch"
            # (third) component has been specified.
            $versionParts = $versionString.Split('.');
            if ($versionParts.Length -lt 3) {
                $versionString = "$versionString.0"
            }

            if ($PSVersionTable.PSEdition -eq "Core") {
                $parsedVersion = New-Object -TypeName "System.Management.Automation.SemanticVersion" -ArgumentList $versionString
            }
            else {
                $parsedVersion = New-Object -TypeName "System.Version" -ArgumentList $versionString
            }
        }

        return $parsedVersion
    }

    foreach ($module in $modules) {
        if ($module.PrivateData -and
            $module.PrivateData.PSData -and
            $module.PrivateData.PSData.Extensions) {

            Write-Verbose "Found module with extensions: $($module.Name)"

            foreach ($extension in $module.PrivateData.PSData.Extensions) {

                Write-Verbose "Comparing against module extension: $($extension.Module)"

                $minimumVersion = ParseVersion $extension.MinimumVersion
                $maximumVersion = ParseVersion $extension.MaximumVersion

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
