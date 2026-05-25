---
external help file: Plaster-help.xml
Module Name: Plaster
online version: https://github.com/PowerShellOrg/Plaster/blob/master/docs/en-US/ConvertTo-JsonManifest.md
schema: 2.0.0
---

# ConvertTo-JsonManifest

## SYNOPSIS
Converts a Plaster XML manifest to JSON format.

## SYNTAX

```
ConvertTo-JsonManifest [-XmlManifest] <XmlDocument> [-Compress] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Converts an XML-format Plaster manifest (plasterManifest.xml) to the JSON format
(plasterManifest.json) used by Plaster 2.0. Accepts an XmlDocument from
Test-PlasterManifest via the pipeline or the -XmlManifest parameter and returns
the resulting JSON as a string.

## EXAMPLES

### Example 1
```powershell
$xml = Test-PlasterManifest -Path .\plasterManifest.xml
ConvertTo-JsonManifest -XmlManifest $xml | Set-Content .\plasterManifest.json
```

Converts plasterManifest.xml and writes the result to plasterManifest.json.

### Example 2
```powershell
Test-PlasterManifest -Path .\plasterManifest.xml | ConvertTo-JsonManifest | Set-Content .\plasterManifest.json
```

Pipes the validated manifest directly into ConvertTo-JsonManifest.

## PARAMETERS

### -Compress
Omits white space and indented formatting in the output JSON string.

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

### -XmlManifest
The parsed XML manifest to convert. Use Test-PlasterManifest to load and validate
a plasterManifest.xml file before passing it to this function.

```yaml
Type: XmlDocument
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Xml.XmlDocument
The validated XML manifest returned by Test-PlasterManifest.

## OUTPUTS

### System.String
A JSON string representation of the Plaster manifest.

## NOTES

## RELATED LINKS

[Test-PlasterManifest](https://github.com/PowerShellOrg/Plaster/blob/master/docs/en-US/Test-PlasterManifest.md)
