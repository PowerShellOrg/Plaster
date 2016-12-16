# Plaster Release History

## 1.0.1
### Friday, December 16, 2016

- Fixed issue with the used of `GetModule -FullyQualifiedName` on PowerShell v3

## 1.0.0
### Friday, December 16, 2016

- First official release shipped to the PowerShell Gallery!

## 0.3.0
### Saturday, November 5, 2016

- Updated build script with support for building help from markdown files, building updatable help files and generating file catalog.
- Initial release shows the basics of what this module could do.

## 0.2.0
### Sunday, July 31, 2016

- Introduced new directive `<templateFile>` that implicitlys expands the specified file(s), allowing the
  template author to set the target file encoding.  This new directive supports a wildcard source specifier
  like the `<file>` directive.  With this change, `<file>` no longer supports template expansion and as result
   the `template` and `encoding` attributes have been removed.
- Restructured the module source to follow best practice of separating infrastructure from module files.
- Fixed #47: How to create empty directories.  The `<file>` directive supports this now.
- Fixed #58: File recurse does not work anymore.
