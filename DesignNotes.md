# Plaster Design Draft

This document aims to lay out a rough design for a new module named Plaster which creates PowerShell project artifacts from template files.

## Design Goals

- Modular template design so that user can choose which elements get added to their project (exclude tests but include build script, etc)
- Flexibility on template package sources but integration with PowerShell Gallery for easy template discovery
- Allow creation of new templates by using and customizing existing templates; template dependency model

## Design Issues

- Should we follow a declarative approach like NuGet/VSIX or an imperative approach like Yeoman?
  Yeoman at least runs in a JS sandbox (I think).  Allowing arbitrary PowerShell script is a bit scary.
  **DECISION:** go with declarative to make it simpler to author a package and safer for the end user by being able
  to limit what a template package can do to your system.
- Use of ShouldProcess is a duh.  However, when you run the command without -Verbose, you get no output.  And the
  verbose output is formatted "Should Process" style.  I think we should consider Yeoman style output if -Verbose/-Whatif
  is not specified. Maybe even with a dash of color??  **DECISION** we will generate output indicating what the
  template is doing even when -Verbose or -WhatIf is specified.  We will make limited use of color similar to
  Yeoman's use of color.
- After having run the Invoke-Plaster command for a few days, I'mm already pining for a Yeoman like `store` feature
  where I can add `parameter` attribute to say that the parameter can be stored and then its value recalled as the
  `default` value.  So after I've entered my name or copyright notice once, it can be stored and used as the
  default value instead of the template provided default value.
- There are several places where we want to allow for parameter substitution: inside the template manifest file and inside of content files.
  With the template manifest file you may want to use a parameter in a file copy command e.g.:
  ```xml
  <file source='Module.psm1' destination='$($Parameters.ModuleName).psm1'/>
  ```
  This approach has the benefit of being easy to implement in Plaster.  We just throw this string at `$ExecutionContext.InvokeCommand.ExpandString()`.
  This is very flexible, if you need the year use `$([DateTime]::Now.Year)` or if you need a new GUID use `$([Guid]::NewGuid())`. Two caveats (at least), first
  where you need a new guid you will likely need it again.  VSIX solves this by offering predefined variables GUID0 thru GUID10.  Second, it is
  dangerous because you can execute arbitrary code in $() e.g. `$(Remove-Item $home\* -Recurse -Force)` - with flexibility comes greater danger.

  Another option that would be safer is to have the user specify a `name` of a variable that will be created by PowerShell and that they
  can later reference by name e.g. `${PARAM_ModuleName}` or maybe `${PLASTER_ModuleName}`.  We could even allow variables like `${env:COMPUTERNAME}`
  and `${ShellId}`.
  If we don't require an expression like a property getter e.g. `$Parameters.ModuleName` then we can use a PS V5
  feature to `EscapeVariables` before they get passed to ExpandString e.g.:
  ```powershell
  $varRefStr = "`${$([System.Management.Automation.Language.CodeGeneration]::EscapeVariableName($var))}"
  $ExecutionContext.InvokeCommand.ExpandString($vaRefStr)
  ```
  This approach should eliminate arbitrary code execution but we would probably need to provide a whole set of predefined variables.  Looking at
  [VSIX list of template parameters](https://msdn.microsoft.com/en-us/library/eehb4faa.aspx) gives a good idea of what we might want to predefine.
  On the positive side, we wouldn't need to resort to constrained runspace / restricted language mode.  These variables would need to be in a
  different "namespace" than user-defined parameters.  Maybe use `${PARAM_UserDefinedName}` for user-defined parameters and `${PLASTER_GUID0}`
  for built-in variables.

  The use of "PowerShell" syntax works pretty well for specifying attribute values in the plasterManifest.xml file.  One exception is with
  `choice label` attributes.  You specify something like `&Yes` where the `&` indicates the shortcut character.  Unfortunately that isn't
  legal XML so you have to use `&amp;Yes`.  Not a big deal but not ideal.  The nice thing about using PowerShell syntax is that A)
  user's will just know it and B) it handles delineation between the variable identifier and subsequent text e.g.
  `destination='$(PARAM_ModuleName).psm1'`.

  The other place for variable substituion is within content files.  Using PowerShell syntax for template variable substitution inside a PS1
  file will be a bit trickier because the syntax is valid PowerShell syntax.  So it will be hard to tell what is supposed to be expanded at
  template processing time.  We "could" base it on a regex like `\${(PARAM|PLASTER)_[^}]+}` but that could perform some unexpected substitutions.

  Another option is to use invalid PowerShell syntax of some form that would be less likely to get accidentally substituted e.g.
  ```powershell
  $ModuleManifestName = '<%=$PARAM_ModuleName%>.psd1'
  ```
- Condition support.  Ultimately the template author will want to "conditionally" apply a template directive based on input from the user.
  Perhaps there is a template parameter that requires the user to answer the question "Do you want a PSake build script?".  Based on the
  user's response (or argument value passed to Invoke-Plaster) the template will execute a directive (or not) e.g.:
  ```xml
  <file source='Build.ps1'
        destination='Build.ps1'
        condition='$PARAM_Options -contains "Pester"'/>
  ```
  This requires execution of an expression.  How do we do this but remain safe and not allow arbitrary code execution?

## Concepts

### Template

The core concept for the model.  Can be a template for a single file or a complete directory structure.

### Layer (?)

Provides additional template generation behavior on top of the base template.  Can be used for optional template parts or
for editor-specific template files.  Can we do composition via dependencies?  Have template C require that templates A and
B be laid down first?

## Cmdlets

### Invoke-Plaster

Provides the core functionality for creating a new project artifact from an existing template file.
Current parameters are TemplatePath, DestinationPath.  Eventually will add TemplateZipPath to point
to a ZIP file instead of an uncompressed template directory.

This command will also have dynamic parameters that correspond to the template parameters defined in
the PlasterManifest file.  For instance, given these parameters:
```xml
    <parameters>
        <parameter name='ModuleName' required='true' prompt='Enter the name of the module'/>
        <parameter name='Version' default='1.0.0' store='true' prompt='Enter the version number for the module'/>
        <parameter name='License' type='choice' default='2' prompt='Select a license for your module'>
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
        <parameter name='Options' type='multichoice' default='0,1,2' prompt='Select desired options'>
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
    </parameters>
```

You could invoke the template like so and get prompted for each parameter:

```PowerShell
Invoke-Plaster -TemplatePath $PSScriptRoot\Tests\TemplateRoot1 -DestinationPath $PSScriptRoot\Tests\Out
```

Or you could provide all the required template parameters as dynamic parameters and **not** be prompted
for any of them e.g.:

```PowerShell
Invoke-Plaster -TemplatePath $PSScriptRoot\Tests\TemplateRoot1 -DestinationPath $PSScriptRoot\Tests\Out `
               -ModuleName CoolModule -Version 2.1.1 -License MIT -Options Pester,PSake,Git
```

### New-PlasterManifest

Generates a new Plaster manifest file.

### Test-PlasterManifest

Verifies if the specified file is a valid Plaster manifest file.

### Compress-PlasterTemplate

Compresses (packs) the Plaster manifest file and dir contents into a ZIP file.

#### Items from Keith to integrate:

Musts:

1. Copy pre-created directories and files into a specified location.
2. Prompt user (either UI or via command line parameter) to supply information required by the template e.g. ModuleName, Author, etc.
3. Rename directories and files based on required input from user e.g. ModuleName
4. Replace substitution variables inside file content with input gathered from user e.g. MyModule.Tests.ps1 => $ModuleManifestName = "$__ModuleName__.psd1” Note: we will have to come up with a substitution syntax that can’t interfere with regular PS variables so using $ might be out.
5. Run PowerShell commands as part of “file generation”.  I don’t think we should ship a canned module manifest file.  We should use the New-ModuleManifest command to generate a manifest.  That way, we don’t have to stay in sync if new fields get added by that command.  That does mean that in the template metadata, we will need to be able to specify command name, parameters and map user input variables like ModuleName, Author to parameters to the command.
6. Advertise to environments (console, ISE, VSCode) templates that are suited for that environment.  In ISE I would not want to be offered a template that created a .vscode directory.
7. Support users ability to modify an existing template pkg and have it get picked up by environments like ISE and VSCode.

Wants:

1. Supply as a single file/pkg (probably a zip file).  High want IMO.  :)
2. Metadata for template author.
3. Command to generate a blank template.
4. Command to pack template into that single template pkg file.
