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

    $manifestXml = Test-PlasterManifest -Path $ManifestPath
    $metadata = $manifestXml["plasterManifest"]["metadata"]

    $manifestObj = [PSCustomObject]@{
        Name = $metadata["name"].InnerText
        Title = $metadata["title"].InnerText
        Author = $metadata["author"].InnerText
        Version = [System.Version]::Parse($metadata["version"].InnerText)
        Description = $metadata["description"].InnerText
        Tags = $metadata["tags"].InnerText.split(",") | ForEach-Object { $_.Trim() }
        TemplatePath = $manifestPath.Directory.FullName
    }

    $manifestObj.PSTypeNames.Insert(0, "Microsoft.PowerShell.Plaster.PlasterTemplate")
    $addMemberSplat = @{
        MemberType = 'ScriptMethod'
        InputObject = $manifestObj
        Name = "InvokePlaster"
        Value = { Invoke-Plaster -TemplatePath $this.TemplatePath }
    }
    Add-Member @addMemberSplat
    return $manifestObj | Where-Object Name -Like $Name | Where-Object Tags -Like $Tag
}
