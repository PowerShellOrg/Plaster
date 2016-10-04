# Creating a Plaster Manifest
## about_Plaster_CreatingAManifest     

# SHORT DESCRIPTION
This about topic will explain the schema of a Plaster Manifest. 

For nearly all uses the `New-PlasterManifest` command is correct approach to start with, as this will ensure you generate a valid base manifest.

# LONG DESCRIPTION
This about topic will explain the schema of a Plaster Manifest. 

For nearly all uses the `New-PlasterManifest` command is correct approach to start with, as this will ensure you generate a valid base manifest.

This topic serves to document the existing manifest schema, currently version `0.4`, using the example Plaster manifest `NewModuleTemplate`.

## The manifest base 
The overall structure of the manifest (shown below) consists of three main sections, `metadata`, `parameters` and `content`. 

The `metadata` section contains data about the manifest itself, including `title` and `version` of the manifest. 

The `parameters` section contains information about the data that needs to be gathered from the user, either as text, or as prompted choices.

The final section, `content`, contains the information on how to name and structure the output of the template from the source files, as well as other data like required modules or informational messages to the user.

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
The metadata section contains information about the Plaster manifest itself and requires the following data:

- `name`        - Manifest name. This value is mandatory.
- `id`          - The ID is the unique identifier used for the storing users
parameter data and makes sure that the store doesn't get used with another 
template. This field is automatically generated if not given a value.
- `version`     - Version of the manifest. Defaults to 1.0.0.
- `title`       - Manifest name used in menu lists. Defaults to `name`.
- `description` - (Optional) Manifest description summary.
- `author`      - (Optional) Authors name or details.
- `tags`        - (Optional) Tags used to describe the purpose of the template.

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
- `store`   - Specifies the store type of the value. This is optional, as not all input data should necessarily be stored. The supported types are the same as the available parameter types. 

### Parameter Type: Text
In interactive mode, the `text` parameter type results in a prompt for a string of text:
```xml
<parameter name='ModuleName' type='text' prompt='Enter the name of the module'/>
```

This parameter definition results in the following prompt:
```
Enter the name of the module: FooUtils
```

Additionally, a default value can be specified, as shown in the next example:
```xml
<parameter name='Version' type='text' default='1.0.0' prompt='Enter the version number for the module'/>
```

This results in the following output, with the default value in parentheses:
```
Enter the version number for the module (1.0.0):
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
The `multichoice` parameter asks for one or more of the available options (supplied as a comma seperated list of choices). This choice type also provides a help option '`?`' used to display the help text:
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
TODO: Explain how the user-email parameter type works.

## Content
TODO: Talk about the content block.

# EXAMPLES
You can create a base plaster manifest by running the New-PlasterManifest command.

# NOTE
You can find additional information about Plaster at the [GitHub page](https://github.com/PowerShell/Plaster)

# TROUBLESHOOTING NOTE
This topic is not yet complete and Plaster is not yet v1.

# SEE ALSO
- https://github.com/PowerShell/Plaster

# KEYWORDS
- Plaster Manifest