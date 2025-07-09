function Get-ManifestsUnderPath {
    <#
    .SYNOPSIS
    Retrieves Plaster manifest files under a specified path.

    .DESCRIPTION
    This function searches for Plaster manifest files (`plasterManifest.xml`)
    under a specified root path and returns template objects created from those
    manifests.

    .PARAMETER RootPath
    The root path to search for Plaster manifest files.

    .PARAMETER Recurse
    Whether to search subdirectories for manifest files.

    .PARAMETER Name
    The name of the template to retrieve.
    If not specified, all templates will be returned.

    .PARAMETER Tag
    The tag of the template to retrieve.
    If not specified, templates with any tag will be returned.

    .EXAMPLE
    Get-ManifestsUnderPath -RootPath "C:\Templates" -Recurse -Name "MyTemplate" -Tag "Tag1"

    Retrieves all Plaster templates named "MyTemplate" with the tag "Tag1"
    under the "C:\Templates" directory and its subdirectories.

    .NOTES
    This is a private function used internally by Plaster to manage templates.
    It is not intended for direct use by end users.
    #>
    [CmdletBinding()]
    param(
        [string]
        $RootPath,
        [bool]
        $Recurse,
        [string]
        $Name,
        [string]
        $Tag
    )
    $getChildItemSplat = @{
        Path = $RootPath
        Include = "plasterManifest.xml", "plasterManifest.json"
        Recurse = $Recurse
    }
    $manifestPaths = Get-ChildItem @getChildItemSplat
    foreach ($manifestPath in $manifestPaths) {
        $newTemplateObjectFromManifestSplat = @{
            ManifestPath = $manifestPath
            Name = $Name
            Tag = $Tag
            ErrorAction = 'SilentlyContinue'
        }
        New-TemplateObjectFromManifest @newTemplateObjectFromManifestSplat
    }
}
