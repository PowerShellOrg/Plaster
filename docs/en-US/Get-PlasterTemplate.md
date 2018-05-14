---
external help file: Plaster-help.xml
online version: https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Get-PlasterTemplate.md
schema: 2.0.0
---

# Get-PlasterTemplate

## SYNOPSIS
Retrieves a list of available Plaster templates that can be used with the Invoke-Plaster
cmdlet.

## SYNTAX

### Path
```
Get-PlasterTemplate [[-Path] <String>] [[-Name] <String>] [[-Tag] <String>] [-Recurse] [<CommonParameters>]
```

### IncludedTemplates
```
Get-PlasterTemplate [-IncludeInstalledModules] [[-Name] <String>] [[-Tag] <String>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves a list of available Plaster templates from the specified path or from
the set of templates that are shipped with Plaster.  Specifying no arguments will
cause only the built-in Plaster templates to be returned.  Using the -IncludeInstalledModules
switch will also search the PSModulePath for PowerShell modules that advertise
Plaster templates that they include. Using the -Name parameter limits the results based on name.
Using the -Tag parameter limits the results based on the template tags.


The objects returned from this cmdlet will provide details about each individual
template that was retrieved.  Use the TemplatePath property of a template object as
the input to Invoke-Plaster's -TemplatePath parameter.

## EXAMPLES

### Example 1
```
PS C:\> $templates = Get-PlasterTemplate

PS C:\> Invoke-Plaster -TemplatePath $templates[0].TemplatePath -DestinationPath ~\GitHub\NewModule
```

This will get the list of built-in Plaster templates.  The first template returned is then used to
create a new module at the specifed path.

### Example 2
```
PS C:\> $templates = Get-PlasterTemplate -IncludeInstalledModules

PS C:\> Invoke-Plaster -TemplatePath $templates[0].TemplatePath -DestinationPath ~\GitHub\NewModule
```

This will get a list of Plaster templates, both built-in and included with installed
modules.  The first template returned is then used to create a new module at
the specifed path.

### Example 3
```
PS C:\> $templates = Get-PlasterTemplate -Path c:\MyPlasterTemplates -Recurse

PS C:\> Invoke-Plaster -TemplatePath $templates[0].TemplatePath -DestinationPath ~\GitHub\NewModule
```

This will get a list of Plaster templates found recursively under c:\MyPlasterTemplates
The first template returned is then used to create a new module at the specifed path.

### Example 4
```
PS C:\> $template = Get-PlasterTemplate -Name NewPowerShellScriptModule

PS C:\> Invoke-Plaster -TemplatePath $template.TemplatePath -DestinationPath ~\GitHub\NewModule
```

This will get the built-in Plaster template with the name NewPowerShellScriptModule.
It will then use that template to create a new module at the specified path.

### Example 5
```
PS C:\> $templates = Get-PlasterTemplate -IncludeInstalledModules -Name new*

PS C:\> Invoke-Plaster -TemplatePath $templates[0].TemplatePath -DestinationPath ~\GitHub\NewModule
```

This will get a list of Plaster templates, both built-in and included with installed
modules, where the name matches 'new*'.
It will then use the first template found to create a new module at the specified path.

### Example 6
```
PS C:\> $templates = Get-PlasterTemplate -IncludeInstalledModules -tag module*

PS C:\> $templates[0].InvokePlaster()
```

This will get a list of Plaster templates, both built-in and included with installed
modules, where the name matches 'module*'.
It will then use the first template found to create a new module at the specified path
using the InvokePlaster script method that is available on the returned object.
## PARAMETERS

### -IncludeInstalledModules
Initiates a search for Plaster templates inside of installed modules.

```yaml
Type: SwitchParameter
Parameter Sets: IncludedTemplates
Aliases: IncludeModules

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Specifies a path to a folder containing a Plaster template or multiple template folders.
Can also be a path to plasterManifest.xml.

```yaml
Type: String
Parameter Sets: Path
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
Indicates that this cmdlet gets the items in the specified locations and in all child items of the locations.

```yaml
Type: SwitchParameter
Parameter Sets: Path
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Limits the templates returned to those that match the template name. Wildcard characters are permitted.

```yaml
Type: String
Parameter Sets: Path, IncludedTemplates
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
Limits the templates returned to those that match the template tags. Wildcard characters are permitted.

```yaml
Type: String
Parameter Sets: Path, IncludedTemplates
Aliases:

Required: False
Position: Named
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
The first positional parameter is a filesystem path under which templates might be
found.  The -Recurse switch will cause this path to be searched recursively.

## OUTPUTS

### System.Object
This output object provides the following properties:

- Name: The name of the template
- Title: The title of the template
- Author: The author of the template
- Version: The version of the template
- Description: Text describing the template and what it creates
- Tags: A list of tag strings which categorize the template
- TemplatePath: The template's folder path in the filesystem

This output object provides the following methods:

- InvokePlaster(): Runs Invoke-Plaster against the template

## NOTES

## RELATED LINKS

[Invoke-Plaster](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Invoke-Plaster.md)
