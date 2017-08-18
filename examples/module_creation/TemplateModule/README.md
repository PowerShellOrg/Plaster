# Plaster Template Module Example

This file contains a simple PowerShell module which includes a Plaster template.
The important part to note is in the `PrivateData` section of the `TemplateModule.psd1`
file:

```powershell
PrivateData = @{

    PSData = @{

        Extensions = @(
            @{
                Module = "Plaster"
                MinimumVersion = "0.3.0"
                Details = @{
                    TemplatePaths = @("TemplateOne", "TemplateTwo")
                }
            }
        )
    } # End of PSData hashtable

} # End of PrivateData hashtable
```

A PowerShell module which includes Plaster templates should add an `Extensions` section
in their `PrivateData.PSData` object using the format shown above.  You can target a specific
version range of Plaster using the `MinimumVersion` (shown) and `MaximumVersion` properties
(not shown).  For now the only property in the `Details` object is `TemplatePaths` which
is a simple list of folder paths under the module's installation path which contain `plasterManifest.xml`
files.

The `TemplateOne` and `TemplateTwo` subfolders both contain a simple, standard `plasterManifest.xml`
which needs no extra configuration to be shipped as part of a PowerShell module.
