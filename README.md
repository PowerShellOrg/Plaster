# Plaster

[![Build status](https://ci.appveyor.com/api/projects/status/o9rtmv1n8hh6qgg1?svg=true)](https://ci.appveyor.com/project/PowerShell/plaster) [![Join the chat at https://gitter.im/PowerShell/Plaster](https://badges.gitter.im/PowerShell/Plaster.svg)](https://gitter.im/PowerShell/Plaster?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Plaster is a template-based file and project generator written in PowerShell.  Its purpose is to
streamline the creation of PowerShell module projects, Pester tests, DSC configurations,
and more. File generation is performed using crafted templates which allow the user to
fill in details and choose from options to get their desired output.

You can think of Plaster as [Yeoman](http://yeoman.io) for the PowerShell community.

## Installation

If you have the [PowerShellGet](https://msdn.microsoft.com/powershell/gallery/readme) module installed
you can enter the following command:

```PowerShell
Install-Module Plaster -Scope CurrentUser
```

Alternatively you can download a ZIP file of the latest version from our [Releases](https://github.com/PowerShell/Plaster/releases)
page.

## Documentation

You can learn how to use Plaster and write your own templates by reading our documentation:

- [About Plaster](docs/en-US/about_Plaster.help.md)
- [Creating a Plaster Manifest](docs/en-US/about_Plaster_CreatingAManifest.help.md)
- [Cmdlet Documentation](docs/en-US/Plaster.md)

## Maintainers

- [Keith Hill](https://github.com/rkeithhill) - [@r_keith_hill](http://twitter.com/r_keith_hill)
- [David Wilson](https://github.com/daviwil) - [@daviwil](http://twitter.com/daviwil)
- [Dave Green](https://github.com/davegreen) - [@neongreenie](http://twitter.com/neongreenie)

## License

This project is [licensed under the MIT License](LICENSE).
