---
external help file: Plaster-help.xml
online version: https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Invoke-Plaster.md
schema: 2.0.0
---

# Invoke-Plaster

## SYNOPSIS
Invokes the specified Plaster template which will scaffold out a file or a set of files and directories.

## SYNTAX

```
Invoke-Plaster [-TemplatePath] <String> [-DestinationPath] <String> [-Force] [-NoLogo] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Invokes the specified Plaster template which will scaffold out a file or a set of files and directories.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Invoke-Plaster -TemplatePath . -Destination ~\GitHub\NewModule
```

This will invoke the Plaster template in the current directory.
The template will generate any files and
directories in the ~\GitHub\NewModule directory.

### -------------------------- EXAMPLE 2 --------------------------
```
Invoke-Plaster -TemplatePath . -Destination ~\GitHub\NewModule -ModuleName Foo -Version 1.0.0
```

This will invoke the Plaster template in the current directory using dynamic parameters ModuleName and
Version extracted from the parameters section of the manifest file.
The template will generate any files and
directories in the ~\GitHub\NewModule directory.

## PARAMETERS

### -TemplatePath
Specifies the path to the template directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationPath
Specifies the path to directory in which the template will use as a root directory when generating files.
If the directory does not exist, it will be created.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Specify Force to override user prompts for conflicting handling.
This will override the confirmation
prompt and allow the template to overwrite existing files.

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

### -NoLogo
Suppresses the display of the Plaster logo.

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[New-PlasterManifest
Test-PlasterManifest]()

