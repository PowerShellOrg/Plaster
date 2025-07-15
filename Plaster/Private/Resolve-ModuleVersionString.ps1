function Resolve-ModuleVersionString {
    <#
    .SYNOPSIS
    Resolve a module version string to a System.Version or
    System.Management.Automation.SemanticVersion object.

    .DESCRIPTION
    This function takes a version string and returns a parsed version object.
    It ensures that the version string is in a valid format, particularly for
    Semantic Versioning 2.0, which requires at least three components
    (major.minor.patch). If the patch component is missing, the function will
    append ".0" to the version string.

    .PARAMETER versionString
    The version string to resolve.

    .EXAMPLE
    Resolve-ModuleVersionString -versionString "1.2"

    This example resolves the version string "1.2" to a valid version object.
    .NOTES
    This function is designed to be used within the Plaster module to ensure consistent version handling.
    It is not intended for direct use outside of the Plaster context.
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        $VersionString
    )

    # We're targeting Semantic Versioning 2.0 so make sure the version has
    # at least 3 components (X.X.X).  This logic ensures that the "patch"
    # (third) component has been specified.
    $versionParts = $VersionString.Split('.')
    if ($versionParts.Length -lt 3) {
        $VersionString = "$VersionString.0"
    }

    if ($PSVersionTable.PSEdition -eq "Core") {
        $newObjectSplat = @{
            TypeName = "System.Management.Automation.SemanticVersion"
            ArgumentList = $VersionString
        }
        return New-Object @newObjectSplat
    } else {
        $newObjectSplat = @{
            TypeName = "System.Version"
            ArgumentList = $VersionString
        }
        return New-Object @newObjectSplat
    }
}
