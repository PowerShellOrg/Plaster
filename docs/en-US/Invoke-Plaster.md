---
external help file: Plaster-help.xml
Module Name: Plaster
online version: https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Invoke-Plaster.md
schema: 2.0.0
---

# Invoke-Plaster

## SYNOPSIS
Invokes the specified Plaster template which will scaffold out a file or a set of files and directories.

## SYNTAX

```
Invoke-Plaster [-TemplatePath] <String> [-DestinationPath] <String> [-Force] [-NoLogo] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Invokes the specified Plaster template which will scaffold out a file or a
set of files and directories.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Plaster -TemplatePath . -Destination ~\GitHub\NewModule
```

This will invoke the Plaster template in the current directory.
The template will generate any files and
directories in the ~\GitHub\NewModule directory.

### EXAMPLE 2
```
Invoke-Plaster -TemplatePath . -Destination ~\GitHub\NewModule -ModuleName Foo -Version 1.0.0
```

This will invoke the Plaster template in the current directory using dynamic
parameters ModuleName and Version extracted from the parameters section of
the manifest file. The template will generate any files and directories in
the ~\GitHub\NewModule directory.

Note: The parameters -ModuleName and -Version are dynamically added from the plaster manifest file in the current directory. If you run this command it may fail if the manifest file you are testing with does not contain these parameters.

## PARAMETERS

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

### -DestinationPath
Specifies the path to directory in which the template will use as a root directory when generating files.
If the directory does not exist, it will be created.

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

### -PassThru
Returns an InvokePlasterInfo object with the following fields:

* TemplatePath
* DestinationPath
* Success
* CreatedFiles
* UpdatedFiles
* MissingModules

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplatePath
Specifies the path to the template directory.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[New-PlasterManifest](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/New-PlasterManifest.md)
[Test-PlasterManifest](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Test-PlasterManifest.md)

