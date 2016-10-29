# Plaster
## about_Plaster

# SHORT DESCRIPTION
Plaster is a scaffolding engine for PowerShell. It can be used to create a single file such as a DSC resource
script file. Or it can be used to scaffold a set of related files and directories such as the files required for
a PowerShell module with Pester tests.

# LONG DESCRIPTION
Plaster operates on a Plaster template which consists of a manifest file (plasterManifest.xml) and a set of
content files and directories that will be copied to the destination path the user chooses. The manifest is an
XML file that consists of the three sections: metadata, parameters, and content.

The metadata section of the manifest is used to supply information about the template e.g.
a unique id, name, version, title, author and tags.

The parameters section of the manifest is used to describe choices the template user can choose from.
Those choices are then used to conditionally create files and folders and modify existing files under the specified
destination path. These parameters can be specified via dynamic parameters for non-interactive scenarios.

The content section is used to specify what actions the template will perform under the user's chosen
destination directory. This includes copying files to the destination, copy & expanding template files,
modifying files, verifying required modules are installed and displaying messages to the user.

See the help topic about_Plaster_CreatingAManifest for more details on authoring a Plaster manifest file.

# LOCALIZATION
Plaster supports template localization by support multiple manifest files suffixed with the local e.g.
plasterManifest_fr-FR.xml or plasterManifest_de-DE.xml. The strings displayed to the user in these manifest
files should be in the corresponding language.

# SEE ALSO
- https://github.com/PowerShell/Plaster
- [about_Plaster_CreatingAManifest](https://github.com/PowerShell/Plaster/blob/master/docs/en-US/about_Plaster_CreatingAManifest.help.md)
