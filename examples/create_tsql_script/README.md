# Plaster Examples

## Script for creating a T-SQL Scripts
This example demonstrates a very simple template which could be used by DBA to prepare script to configure SQL Server instances


The example demonstrates
- plasterManifest.xml was created using New-PlasterManifest:
New-PlasterManifest -Path plasterManifest.xml -TemplateName "ChangeErrorRecycleLog" -Title "Change Error Recycle Log" -Description "Create T-SQL Script to change number of kept logs in SQL"
- edition of the parameters and content tags
- tested with Test-PlasterManifest .\plasterManifest.xml -Verbose
- creation of a parameter to get the name of the instance; this is used in comment only
- creation of parameter to get the number of logs; please note that parameters are text so anything can be entered at the input stage. The check will be made in the template by casting the parameter as int
- use of template file directive to generate files from template; the expression uses a replace expression to replace backslashes by underscores in filename. As we dealing with CDATA in attroibutes, quotes are specific XML Entities and must be escaped. The original powershell expression is  $var -replace('\\','_')  [double backslashes are due to regex]
- use of expression to replace parameter in the template file
- use of powershell authorized expressions to generate the date
-

To run this example, cd to the folder and execute:
```powershell
Import-Module ..\..\src\Plaster.psd1
Invoke-Plaster -TemplatePath . -Destination ..\SQLDemo
```
This will prompt you for the template's required parameters as defined in plasterManifest.xml.  If you
run the Invoke-Plaster command a second time, you see Plaster's file conflict handling.  You can use
the `-Force` parameter to automatically overwrite existing files.

You can bypass the interactive prompting by providing the necessary parameters directly to Invoke-Plaster as
demonstrated below.  Note: you will get autocompletion support for template parameters as they are added
as dynamic parameters to Invoke-Plaster.
```powershell
$PlasterParams = @{
    TemplatePath = $PWD
    Destination = '..\SQLDemo'
    NumberLogs = '10'
	InstanceName = 'SQLSRV\MYINSTANCE'
}

Invoke-Plaster @PlasterParams -Force
```

Re-Run  Invoke-Plaster multiple times, so you'll see how Plaster handles identical and conflict files