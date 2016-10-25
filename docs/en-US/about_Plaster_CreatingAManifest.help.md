# Creating a Plaster Manifest
## about_Plaster_CreatingAManifest

# SHORT DESCRIPTION
This about topic will explain the schema of a Plaster Manifest.

For nearly all uses the `New-PlasterManifest` command is correct approach to start with, as this will ensure you generate a valid base manifest.

# LONG DESCRIPTION
This about topic will explain the schema of a Plaster Manifest.

For nearly all uses the `New-PlasterManifest` command is correct approach to start with, as this will ensure you generate a valid base manifest.

This topic serves to document the existing manifest schema, currently version `0.4`, using the example Plaster manifest `NewModuleTemplate`. The current plaster manifest schema can be found at [PlasterManifest-v1.xsd](https://github.com/PowerShell/Plaster/blob/master/src/Schema/PlasterManifest-v1.xsd)

## The manifest base
The overall structure of the manifest (shown below) consists of three main sections, `metadata`, `parameters` and `content`.

The `metadata` section contains data about the manifest itself, including `title` and `version` of the manifest.

The `parameters` section contains information about the data that needs to be gathered from the user, either as text, or as prompted choices.

The final section, `content`, contains the information on how to name and structure the output of the template from the source files, as well as other data like required modules or informational messages to the user.

The Plaster manifest attribute `schemaVersion` indicates the minimum required Plaster schema capable of reading the manifest. This will be automatically created when running `New-PlasterManifest` and populated with the current schema version.

```xml
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata></metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
```

## Metadata
The `metadata` section contains information about the Plaster manifest itself and requires the following data:

- `name`        - Manifest name. This value is mandatory.
- `id`          - The ID is the unique identifier used for the storing users
parameter data and makes sure that the store doesn't get used with another
template. This field is automatically generated if not given a value.
- `version`     - Version of the manifest. Defaults to 0.1.0.
- `title`       - Manifest name used in menu lists. Defaults to `name`.
- `description` - Manifest description summary.
- `tags`        - Tags used to describe the purpose of the template.
- `author`      - (Optional) Authors name or details.

An example of the settings explained above can be shown by running `New-PlasterManifest` this would give you something similar to the the following:
```xml
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="0.4" xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">
  <metadata>
    <name>NewPowerShellModule</title>
    <id>38bd80d9-3a47-4916-9220-bed383d90876</id>
    <version>0.2.0</version>
    <title>New PowerShell Module</title>
    <description>Plaster template for creating the files for a PowerShell module.</description>
    <author>Plaster Project</author>
    <tags>Module, ModuleManifest, Build</tags>
  </metadata>
  <parameters></parameters>
  <content></content>
</plasterManifest>
```

## Parameters
Parameters are pieces of information that Plaster will ask for to build the template. Parameters are optional directives, as all the data for the template could potentially be pre-configured, but that would defeat the purpose of the Plaster!

Data for these parameters can be taken either as parameters to `Invoke-Plaster`, or will be prompted for by Plaster. Specifying the attributes for parameters is done using the following data:

- `name`    - The name of the parameter. This is used as the identity to refer to and store the parameter value.
- `type`    - the type of parameter, currently supported values are `text`, `choice`, `multichoice`, `user-fullname` and `user-email`.
- `default` - The default value of the parameter, displayed in the UI inside parentheses. This is an optional attribute to assist users of your template. Default values for the `user-fullname` and `user-email` parameter types are retrieved from the user's .gitconfig if no stored value is available.
- `store`   - Specifies the store type of the value. This is optional, as not all input data should necessarily be stored. The supported types are the same as the available parameter types. Stored data is saved to a user profile folder and the filename is a function of the template name and version (`Name-Version-ID.clixml`).

Locations for the template input store differ based on operating system. Here is the list of possible locations and when they will be used:

Windows
- `$env:LOCALAPPDATA\Plaster`.

Linux
- `$XDG_DATA_HOME/plaster` (If `$XDG_DATA_HOME` has a value).
- `$Home/.local/share/plaster` (No `$XDG_DATA_HOME` value).

Other
- `$Home/.plaster`.

### Parameter Type: Text
In interactive mode, the `text` parameter type results in a prompt for a string of text:
```xml
<parameter name='ModuleName'
           type='text'
           prompt='Enter the name of the module'/>
```

This parameter definition results in the following prompt:
```
Enter the name of the module: FooUtils
```

Additionally, a default value can be specified, as shown in the next example:
```xml
<parameter name='Version'
           type='text'
           default='0.1.0'
           prompt='Enter the version number for the module'/>
```

This results in the following output, with the default value in parentheses:
```
Enter the version number for the module (0.1.0):
```

### Parameter Type: Choice
In interactive mode, the `choice` parameter type asks for a single choice from the available options. This choice type also provides a help option '`?`' used to display the help text:

```xml
<parameter name='License' type='choice' default='2' store='text' prompt='Select a license for your module'>
  <choice label='&amp;Apache'
          help="Adds an Apache license file."
          value="Apache"/>
  <choice label='&amp;MIT'
          help="Adds an MIT license file."
          value="MIT"/>
  <choice label='&amp;None'
          help="No license specified."
          value="None"/>
</parameter>
```

This parameter definition results in the following output:
```
Select a license for your module
[A] Apache  [M] MIT  [N] None  [?] Help (default is "M"): ?
A - Adds an Apache license file.
M - Adds an MIT license file.
N - No license specified.
[A] Apache  [M] MIT  [N] None  [?] Help (default is "M"):
```

### Parameter Type: Multi Choice
The `multichoice` parameter asks for one or more of the available options (supplied as a comma separated list of choices). This choice type also provides a help option '`?`' used to display the help text:
```xml
<parameter name='Options' type='multichoice' default='0,1,2' store='text' prompt='Select desired options'>
  <choice label='&amp;Pester test support'
          help="Adds Tests directory and a starter Pester Tests file."
          value="Pester"/>
  <choice label='P&amp;Sake build script'
          help="Adds a PSake build script that generates the module directory for publishing to the PSGallery."
          value="PSake"/>
  <choice label='&amp;Git'
          help="Adds a .gitignore file."
          value="Git"/>
  <choice label='&amp;None'
          help="No options specified."
          value="None"/>
</parameter>
```

This parameter definition results in the following output, including the help output:
```
Select desired options
[P] Pester test support
[S] PSake build script
[G] Git
[N] None
[?] Help
(default choices are P,S,G)
Choice[0]: ?
P - Adds Tests directory and a starter Pester Tests file.
S - Adds a PSake build script that generates the module directory for publishing to the PSGallery.
G - Adds a .gitignore file.
N - No options specified.
Choice[0]:
```

### Parameter Type: Other
The `user-fullname` and `user-email` parameter types are the same as the `text` type, except that they get their default values from from the user's .gitconfig file (if the user has one, and no default is set in the manifest).

Here is an example of the XML for this parameter.
```xml
<parameter name='FullName'
           type='user-fullname'
           prompt='Enter your full name'
           store='text' />
```

This results in the following prompt, with the default value of 'Your Name' coming from your .gitconfig file:
```
Enter your full name (Your Name):
```

## Content
There are a selection of elements in the `content` block that can be used to specify all of the content that should be included with your template and how it should be created and transformed into the end product that the template provides.

The available element types are:
- `file`              - Specify one or more files to copy under the destination folder.
- `templateFile`      - Specify one or more template files to copy and expand under the destination folder.
- `message`           - Display a message to the user.
- `modify`            - Modify an existing file under the destination folder (Used with the `file`/`templateFile` elements).
- `newModuleManifest` - Create a new module manifest file using the `New-ModuleManifest` command.
- `requireModule`     - Checks to see if the specified module is installed. If not, the user is notified of the need to install the module.

### Content element: Common
Currently, there is only one common attribute shared between all current content elements.
- `condition` - Used to determine whether a directive is executed. If the condition evaluates to true, it will execute.

Some elements use the encoding attribute, while not a common attribute, has a common set of possible values:
- `Default`
- `Ascii`
- `BigEndianUnicode`
- `BigEndianUTF32`
- `Oem`
- `Unicode`
- `UTF32`
- `UTF7`
- `UTF8`
- `UTF8-NoBOM`

Element attribute values support the use of Plaster parameters, which are parameter values that can be expanded into file names, or other pieces of information the template deals with. These map to available parameters, licenses and other data that is provided in the template.

TODO: Explain Plaster parameters and provide a list.

### Content element: File
One or more files can be selected (using wild cards like `*`) with each file element. Attribute values support the inclusion of Plaster parameters to control (as an example) the location or the name of the resulting file.

Available attributes for this content element:
- `source`      - Specifies the relative path to the file in the template's root folder.
- `destination` - Specifies the relative path, under the destination folder, to where the file will be copied. Files can only be copied to a location under the destination folder.
- `condition`

A basic example of this content element would be:
```xml
<file source='ReleaseNotes.md'
              destination=''/>
```

Two more complex examples are:
```xml
<file source='Tests\*.tests.ps1'
      destination='test\'
      condition='$PLASTER_PARAM_Options -contains "Pester"'/>
```

```xml
<templateFile source='en-US\about_Module.help.txt'
              destination='en-US\about_${PLASTER_PARAM_ModuleName}.help.txt'/>
```

### Content element: TemplateFile
Specify one or more template files (using wild cards, as with the file element) to copy and expand under the destination folder. Expansion is done by looking through the file and expanding out any Plaster parameters that are found.

Available attributes for this content element:
- `source`      - Specifies the relative path to the file in the template's root folder.
- `destination` - Specifies the relative path, under the destination folder, to where the file will be copied.
- `encoding`    - Specifies the encoding of the file, see `Content Element: Common` for possible values. If you do not specify an encoding, ASCII encoding will be used.
- `condition`

An example of using the template file element:

```xml
<templateFile source='test\Shared.ps1'
              destination='test\Shared.ps1'
              condition="$PLASTER_PARAM_Options -contains 'Pester'"/>
```

### Content element: Message
The message type is a pretty straightforward element with two potential attributes (both optional).

Available attributes for this content element:
- `nonewline` - If true, suppresses output of a newline at the end of the message.
- `condition`

Here is an example of the message element:
```xml
<message>
A message to the user

and other interesting information.
</message>
```

This example shows Plaster parameter expansion working in the message element:
```xml
<message nonewline='true'>`n`nYour new PowerShell module project $PLASTER_PARAM_ModuleName </message>
```

### Content element: Modify
The modify element allows you to replace file contents, allowing you to copy files using the `file` element, then substituting content to meet your needs.

Available attributes for this content element are:
- `replace`   - Specify a replacement operation of the file content.
    - `original`   - The original text, or regular expression match to replace. If just searching for text, regular expression syntax must be used by escaping backslashes and other special characters.
        - `expand` - Whether to expand variables within the original for match.
    - `substitute` - The replacement text to substitute in place of the original text.
        - `expand` - Whether to expand variables within the substitute text.
    - `condition`
- `path`      - Specifies the relative path, under the destination folder, of the file to be modified.
- `encoding`  - Specifies the encoding of the file, see `Content Element: Common` for possible values. If you do not specify an encoding, ASCII encoding will be used.
- `condition`

Here is a simple example of the modify element, using a regular expressions:

```xml
<modify path='.vscode\tasks.json' encoding='UTF8'
        condition="$PLASTER_PARAM_Editor -eq 'VSCode'">
    <replace condition="$PLASTER_FileContent -notmatch '// Author:'">
        <original>(?s)^(.*)</original>
        <substitute expand='true'>// Author: $PLASTER_PARAM_FullName`r`n`$1</substitute>
    </replace>
</modify>
```

#### NOTE: Multiple original, substitute and condition attributes can be used in a single modify element.

### Content element: NewModuleManifest
This element allows you to create a module manifest using the data that has been input to Plaster through Plaster parameters.

Available attributes for this content element:
- `destination`   - Specifies the relative path, under the destination folder, to where the file will be copied.
- `author`        - Specifies the value of the Author property.
- `companyName`   - Specifies the value of the CompanyName property.
- `description`   - Specifies the value of the Description property. Note: this field is required for module submissions to the PowerShell Gallery.
- `moduleVersion` - Specifies the value of the ModuleVersion property.
- `rootModule`    - Specifies the value of the RootModule property.
- `encoding`      - Specifies the encoding of the file, see `Content Element: Common` for possible values. If you do not specify an encoding, the current file encoding will be used.
- `condition`

Here is an example of the `newModuleManifest` element:
```xml
<newModuleManifest destination='src\${PLASTER_PARAM_ModuleName}.psd1'
                   moduleVersion='$PLASTER_PARAM_Version'
                   rootModule='${PLASTER_PARAM_ModuleName}.psm1'
                   author='$PLASTER_PARAM_FullName'
                   description='$PLASTER_PARAM_ModuleDesc'
                   encoding='UTF8-NoBOM'/>
```

### Content element: RequireModule
The `requireModule` element specifies modules that are required under certain conditions resulting from the choices input by the user.

Available attributes for this content element:
- `name`            - Specifies the name of the required module.
- `minimumVersion`  - The required module's minimum version.
- `maximumVersion`  - The required module's maximum version.
- `requiredVersion` - Specifies a specific version of the module. This attribute cannot be used with either the `minimumVersion` or `maximumVersion` attributes. Use this attribute rarely as any update to the module that changes its version will result in this check failing.
- `message`         - Specifies a custom message to display after the standard Plaster message when the specified module's is not available on the target machine. This message should be used to tell the user what functionality will not work without the specified module.
- `condition`

#### NOTE: All versions in this element should be specified in the three part MAJOR.MINOR.PATCH (Semver) format.

```xml
<requireModule name="Pester" condition='$PLASTER_PARAM_Options -contains "Pester"'
               minimumVersion="3.4.0"
               message="Without Pester, you will not be able to run the provided Pester test to validate your module manifest file.`nWithout version 3.4.0, VS Code will not display Pester warnings and errors in the Problems panel."/>
```

# EXAMPLES
You can create a base plaster manifest by running the New-PlasterManifest command.

See the included `NewModule` or `NewDscResourceScript` `plasterManifest.xml` for more examples.

# NOTE
You can find additional information about Plaster at the [GitHub page](https://github.com/PowerShell/Plaster)

# TROUBLESHOOTING NOTE
This topic is not yet complete and Plaster is not yet v1.

# SEE ALSO
- https://github.com/PowerShell/Plaster

# KEYWORDS
- Plaster Manifest