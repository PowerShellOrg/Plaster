function New-TemplateObjectFromManifest {
    <#
    .SYNOPSIS
    Creates a Plaster template object from a manifest file.

    .DESCRIPTION
    This function takes a path to a Plaster manifest file and creates a
    template object from its contents.

    .PARAMETER ManifestPath
    The path to the Plaster manifest file.

    .PARAMETER Name
    The name of the template.
    If not specified, all templates will be returned.

    .PARAMETER Tag
    The tag of the template.
    If not specified, templates with any tag will be returned.

    .EXAMPLE
    Get-TemplateObjectFromManifest -ManifestPath "C:\Templates\MyTemplate\plasterManifest.xml" -Name "MyTemplate" -Tag "Tag1"

    Retrieves a template object for the specified manifest file with the given name and tag.
    .NOTES
    This function is used internally by Plaster to manage templates.
    It is not intended for direct use by end users.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [System.IO.FileInfo]$ManifestPath,
        [string]$Name,
        [string]$Tag
    )

    try{
        $manifestXml = Test-PlasterManifest -Path $ManifestPath
        $metadata = $manifestXml["plasterManifest"]["metadata"]

        $manifestObj = [PSCustomObject]@{
            Name = [string]$metadata.name
            Title = [string]$metadata.title
            Author = [string]$metadata.author
            Version = [System.Version]::Parse([string]$metadata.version)
            Description  = if ($metadata.description) { [string]$metadata.description } else { "" }
                        Tags         = if ($metadata.tags) { ([string]$metadata.tags).split(",") | ForEach-Object { $_.Trim() } } else { @() }
                        TemplatePath = $manifestPath.Directory.FullName
                        Format       = if ($manifestPath.Extension -eq '.json') { 'JSON' } else { 'XML' }
        }

        $manifestObj.PSTypeNames.Insert(0, "Microsoft.PowerShell.Plaster.PlasterTemplate")
        $addMemberSplat = @{
            MemberType = 'ScriptMethod'
            InputObject = $manifestObj
            Name = "InvokePlaster"
            Value = { Invoke-Plaster -TemplatePath $this.TemplatePath }
        }
        Add-Member @addMemberSplat

        # Fix the filtering logic
        $result = $manifestObj
        if ($name -and $name -ne "*") {
            $result = $result | Where-Object Name -like $name
        }
        if ($tag -and $tag -ne "*") {
            # Only filter by tags if the template actually has tags
            if ($result.Tags -and $result.Tags.Count -gt 0) {
                $result = $result | Where-Object { $_.Tags -contains $tag -or ($_.Tags | Where-Object { $_ -like $tag }) }
            } elseif ($tag -ne "*") {
                # If template has no tags but we're filtering for a specific tag, exclude it
                $result = $null
            }
        }
        return $result
    } catch {
        Write-Debug "Failed to process manifest at $($manifestPath.FullName): $($_.Exception.Message)"
        return $null
    }
}
