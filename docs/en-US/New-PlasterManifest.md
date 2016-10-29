---
external help file: Plaster-help.xml
online version: https://github.com/PowerShell/Plaster/blob/master/docs/en-US/New-PlasterManifest.md
schema: 2.0.0
---

# New-PlasterManifest

## SYNOPSIS
Creates a new Plaster template manifest file.

## SYNTAX

```
New-PlasterManifest [[-Path] <String>] -Name <String> [-Id <Guid>] [-TemplateVersion <String>]
 [-Title <String>] [-Description <String>] [-Tags <String[]>] [-Author <String>] [-AddContent] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-PlasterManifest command creates a new Plaster manifest file,
populates its values, and saves the manifest file in the specified path.

Template authors can use this command to create a manifest for their
template. A template manifest is a file named plasterManifest.xml or
plasterManifest_\<culture-name\>.xml. The information stored in the manifest
is used to scaffold files and folders.

The metadata section of the manifest is used to supply information about the
template e.g. a unique id, name, version, title, author and tags.

The parameters section of the manifest is used to describe choices the
template user can choose from. Those choices are then used to conditionally
create files and folders and modify existing files under the specified
destination path.

The content section is used to specify what actions the template will perform
under the user's chosen destination directory. This includes copying files to
the destination, copy & expanding template files, modifying files, verifying
required modules are installed and displaying messages to the user.

See the help topic about_Plaster_CreatingAManifest for more details on
authoring a Plaster manifest file.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-PlasterManifest
```

Creates a basic plasterManifest.xml file in the current directory.

### -------------------------- EXAMPLE 2 --------------------------
```
New-PlasterManifest -TemplateVersion 0.1.0 -Description "Some description." -Tags Module, Publish,Build
```

Creates a plasterManifest.xml file in the current directory with the version set to 0.1.0 and with the
Description and Tags elements populated.

### -------------------------- EXAMPLE 3 --------------------------
```
New-PlasterManifest -AddContent
```

Creates a plasterManifest.xml file in the current directory with the content element filled in with all the
files (except for any plasterManifest files) in and below the specified directory which defaults to the
current directory.

## PARAMETERS

### -AddContent
If specified, the contents of the directory the manifest is being created in will be added to the
manifest's content element.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Author
Specifies the author of the template.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the Plaster template.
This describes what the the template is for.
It is typically used in
an editor like VSCode when displaying additional information about a Plaster template.
A typical title might be "Creates files required for a PowerShell module with optional support for Pester
tests, building with psake and publishing to the PowerShell Gallery."

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Unique identifier for all versions of this template.
The id is a GUID.
Use the same id for each version
of your template.
This will prevent editor environments from listing multiple, installed versions of your
template.
When you keep your template id the same, the editor will list only the latest version of your
template.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [guid]::NewGuid()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Specifies the name of the template.
A template name is required.
For localized manifests, this value
should not be localized.
The name is limited to the characters: aA-zZ0-9_-.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Specifies the path and file name of the new Plaster manifest.
Enter a path and file name with a .xml
extension, such as $pshome\Modules\MyPlasterTemplate\plasterManifest.xml.
NOTE: Plaster requires the manifest
file be named either plasterManifest.xml OR plasterManifest_\<culture-name\>.xml e.g.
plasterManifest_fr-FR.xml.
The default, if no value is provided is to create plasterManifest.xml in the current directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: "$pwd\plasterManifest.xml"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
Specifies an array of tags for the template.
Users can search for templates based on these tags.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplateVersion
Specifies the version of the template.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1.0.0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Title of the Plaster template.
This string is typically used in an editor like VSCode when displaying
a list of Plaster templates.
A typical title might be "New DSC Resource" or "New PowerShell Module".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Name
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
You cannot pipe input to this cmdlet.

## OUTPUTS

### None

## NOTES

## RELATED LINKS

[Invoke-Plaster](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Invoke-Plaster.md)
[Test-PlasterManifest](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Test-PlasterManifest.md)

