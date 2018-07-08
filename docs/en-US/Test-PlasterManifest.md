---
external help file: Plaster-help.xml
Module Name: Plaster
online version: https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Test-PlasterManifest.md
schema: 2.0.0
---

# Test-PlasterManifest

## SYNOPSIS
Verifies that a plaster manifest file is a valid.

## SYNTAX

```
Test-PlasterManifest [[-Path] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Verifies that a plaster manifest file is a valid.
If there are any errors, the details of the errors can be viewed by using the
Verbose parameter.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Test-PlasterManifest MyTemplate\plasterManifest.xml
```

Verifies that the plasterManifest.xml file in the MyTemplate sub-directory
is valid.

### -------------------------- EXAMPLE 2 --------------------------
```
Test-PlasterManifest plasterManifest.xml -Verbose
```

Verifies that the plasterManifest.xml file in the current directory is valid.
If there are any validation errors, using -Verbose will display the details
of those errors.

## PARAMETERS

### -Path
Specifies a path to a plasterManifest.xml file.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: PSPath

Required: False
Position: 0
Default value: "$pwd\plasterManifest.xml"
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
You can pipe the path to a plaster manifest to Test-PlasterManifest.

## OUTPUTS

### System.Xml.XmlDocument
Test-PlasterManifest returns a System.Xml.XmlDocument if the manifest is
valid. Otherwise it returns $null.

## NOTES

## RELATED LINKS

[Invoke-Plaster](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/Invoke-Plaster.md)
[New-PlasterManifest](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/New-PlasterManifest.md)

