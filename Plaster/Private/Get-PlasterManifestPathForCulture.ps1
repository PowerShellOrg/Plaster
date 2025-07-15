function Get-PlasterManifestPathForCulture {
    <#
    .SYNOPSIS
    Returns the path to the Plaster manifest file for a specific culture.

    .DESCRIPTION
    This function checks for the existence of a Plaster manifest file that
    matches the specified culture. It first looks for a culture-specific
    manifest, then checks for a parent culture manifest, and finally falls back
    to an invariant culture manifest if no specific match is found. The function
    returns the path to the manifest file if found, or $null if no matching
    manifest is found.

    .PARAMETER TemplatePath
    The path to the template directory.
    This should be a fully qualified path to the directory containing the
    Plaster manifest files.

    .PARAMETER Culture
    The culture information for which to retrieve the Plaster manifest file.

    .EXAMPLE
    GetPlasterManifestPathForCulture -TemplatePath "C:\Templates" -Culture (Get-Culture)

    This example retrieves the path to the Plaster manifest file for the current culture.
    .NOTES
    This is a private function used by Plaster to locate the appropriate
    manifest file based on the specified culture.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [string]
        $TemplatePath,
        [ValidateNotNull()]
        [CultureInfo]
        $Culture
    )
    if (![System.IO.Path]::IsPathRooted($TemplatePath)) {
        $TemplatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)
    }

    # Check for culture-locale first.
    $plasterManifestBasename = "plasterManifest"
    $plasterManifestFilename = "${plasterManifestBasename}_$($culture.Name).xml"
    $plasterManifestPath = Join-Path $TemplatePath $plasterManifestFilename
    if (Test-Path $plasterManifestPath) {
        return $plasterManifestPath
    }

    # Check for culture next.
    if ($culture.Parent.Name) {
        $plasterManifestFilename = "${plasterManifestBasename}_$($culture.Parent.Name).xml"
        $plasterManifestPath = Join-Path $TemplatePath $plasterManifestFilename
        if (Test-Path $plasterManifestPath) {
            return $plasterManifestPath
        }
    }

    # Fallback to invariant culture manifest.
    $plasterManifestPath = Join-Path $TemplatePath "${plasterManifestBasename}.xml"
    if (Test-Path $plasterManifestPath) {
        return $plasterManifestPath
    }

    # If no manifest is found, return $null.
    # TODO: Should we throw an error instead?
    return $null
}
