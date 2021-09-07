# Plaster

[![Build status](https://ci.appveyor.com/api/projects/status/o9rtmv1n8hh6qgg1?svg=true)](https://ci.appveyor.com/project/PowerShell/plaster)

> **This project has been transferred from Microsoft to PowerShell.org as of 16 June 2020. We hope to bring this project back up to speed. Please allow us some time to get re-organized**.
>

## Current Status

This project has been dormant for a while, which is one of the reasons for the ownership transfer. As the new maintainers get up to speed, the following actions are taking place.

+ Many of the existing issues have been converted into Discussions. If you have an enhancement suggestion or question, please use Discussions. File an Issue for a bug or error.
+ No new pull requests will be considered at this time. It is very likely old, existing PRs will be closed without any action. Although we will take note of the change and possible incorporate it separately.

### Roadmap

The long-term goal is to make sure that the module works in Windows PowerShell 5.1 and PowerShell 7.x, including support for Pester 5.x. The module should have VS Code integration. In the short-term, the focus will be on these items:

+ re-establish a build pipeline
+ revise to take Pester v5 into account
+ verify current documentation
+ verify the module can be used in PowerShell 7.x without error

Once these items have been addressed and the module is stable, we can re-visit ideas and suggestions.

## Background

Plaster is a template-based file and project generator written in PowerShell.  Its purpose is to streamline the creation of PowerShell module projects, Pester tests, DSC configurations, and more. File generation is performed using crafted templates which allow the user to fill in details and choose from options to get their desired output.

You can think of Plaster as [Yeoman](http://yeoman.io) for the PowerShell community.

## Installation

If you have the [PowerShellGet](https://msdn.microsoft.com/powershell/gallery/readme) module installed
you can enter the following command:

```PowerShell
Install-Module Plaster -Scope CurrentUser
```

Alternatively, you can download a ZIP file of the latest version from our [Releases](https://github.com/PowerShellOrg/Plaster/releases)
page.

## Documentation

You can learn how to use Plaster and write your templates by reading our documentation:

+ [About Plaster](docs/en-US/about_Plaster.help.md)
+ [Creating a Plaster Manifest](docs/en-US/about_Plaster_CreatingAManifest.help.md)
+ [Cmdlet Documentation](docs/en-US/Plaster.md)

Or by watching:

+ [Working with Plaster Presentation](https://youtu.be/16CYGTKH73U) by David Christian - [@dchristian3188](https://github.com/dchristian3188)

Or by checking out some blog posts on Plaster:

+ [Working with Plaster](http://overpoweredshell.com/Working-with-Plaster/) by David Christian - [@dchristian3188](https://github.com/dchristian3188)

## Maintainers

+ [Jeff Hicks](https://github.com/jdhitsolutions) - [@jeffhicks](http://twitter.com/jeffhicks)
+ [James Petty](https://github.com/psjamess) - [@PSJamesP](http://twitter.com/PSJamesP)


## License

This project is [licensed under the MIT License](LICENSE).
