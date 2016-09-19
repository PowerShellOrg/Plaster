# Plaster Release History

## 0.2.0
### Sunday, July 31, 2016

- Introduced new directive `<templateFile>` that implicitlys expands the specified file(s), allowing the
  template author to set the target file encoding.  This new directive supports a wildcard source specifier
  like the `<file>` directive.  With this change, `<file>` no longer supports template expansion and as result
   the `template` and `encoding` attributes have been removed.
- Restructured the module source to follow best practice of separating infrastructure from module files.
- Fixed #47: How to create empty directories.  The `<file>` directive supports this now.
- Fixed #58: File recurse does not work anymore.
