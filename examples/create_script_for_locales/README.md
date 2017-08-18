# Plaster Examples

## Script for changing locale
This example demonstrates a very simple template which could be used by administrators to change the locale on a Windows System.
THis is based on https://msdn.microsoft.com/en-us/goglobal/bb964650(en-us).aspx
The Windows API used are beyond the scope of this example, but basically the purpose of the template is to allow to:
- collect the locale the user wants to set
- generate a .xml file based on the parameter
- generate a .cmd that calls the xml
The two files are just what is needed by the system administrator to change the local on any Windows Vista or higher machines 

The example demonstrates
- plasterManifest.xml was created using New-PlasterManifest:
New-PlasterManifest -Path plasterManifest.xml -TemplateName "ChangeUserLocale" -Title "Change User Locale" -Description "Create files to change user locales"
edition of the parameters and content tags
- tested with Test-PlasterManifest .\plasterManifest.xml -Verbose

- creation of parameter to get the locale; please note that a better choice could be to list the full available locales but it is beyond the scope of this simple example. See https://msdn.microsoft.com/en-us/library/cc233982.aspx 
- creation of a choice parameter to know if the choice applies to the current user or all the users on the machine
- use of template file directive to generate files from template
- use of expression to replace the locale chosen in the template file
- use of the if powershell construct to generate ad-hoc line based on choices

To run this example, cd to the NewModuleTemplate folder and execute:
```powershell
Import-Module ..\..\src\Plaster.psd1
Invoke-Plaster -TemplatePath . -Destination ..\Admin-Locale
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
    Destination = '..\Admin-Locale'
    NewLocale = 'en-GB'
	AllUsers='Yes'
}

Invoke-Plaster @PlasterParams -Force
```

Re-Run  Invoke-Plaster multiple times, so you'll see how Plaster handles identical and conflict files