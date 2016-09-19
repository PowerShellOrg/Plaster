# Plaster Design Draft

This document aims to lay out a rough design for a new module named Plaster which creates PowerShell project artifacts from template files.

## Design Goals

- Modular template design so that user can choose which elements get added to their project (exclude tests but include build script, etc)
- Flexibility on template package sources (local directory for testing) but integration with PowerShell Gallery for distribution and easy template discovery
- Allow creation of new templates by customizing existing templates

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
- After having run the Invoke-Plaster command for a few days, I'm already pining for a Yeoman like `store` feature
  where I can add `parameter` attribute to say that the parameter can be stored and then its value recalled as the
  `default` value.  So after I've entered my name or copyright notice once, it can be stored and used as the
  default value instead of the template provided default value. **DECISION** implemented. 'Nuf said.
- There are several places where we want to allow for parameter substitution: inside the template manifest file and inside of content files.
  With the template manifest file you may want to use a parameter in a file copy command e.g.:
  ```xml
  <file source='Module.psm1' destination='${PLASTER_PARAM_ModuleName}.psm1'/>
  ```
  One approach is to throw the attribute text directly at `$ExecutionContext.InvokeCommand.ExpandString()`.
  This is very flexible, if you need the year use `$([DateTime]::Now.Year)` or if you need a new GUID use `$([Guid]::NewGuid())`. Two caveats (at least), first
  where you need a new guid you will likely need it again.  VSIX solves this by offering predefined variables GUID0 thru GUID10.  Second, it is
  dangerous because you can execute arbitrary code in $() e.g. `$(Remove-Item $home\* -Recurse -Force)` - with flexibility comes greater danger.
  The bigger issue here is that we can no longer guarantee `idempotency` when the template is invoked multiple times against the same destination.
  If we can prevent "side effects" from arbitrary code executing in an attribute like `destination` then we can provide a
  good (predictable) experience when invoking the template multiple times againt the same destination folder.

  A better (safe) option is to have the user specify a `name` of a variable that will be created by PowerShell and that they
  can later reference by name e.g. `${PLASTER_PARAM_ModuleName}` We in fact allow any accessible variables like `${env:COMPUTERNAME}`
  and `${ShellId}`.

  **DECISION** we are going with the "safe" approach for now - for attributes that can use parameters.  This includes attributes like `source`,
  `destination` and `condition` as well as some element content e.g. `original` and `substitute` in the modify directive.

  In a future release, we may allow a template to
  execute arbitrary script but that will be inside a special directive perhaps called `<script>`.  The user would be advised the template wants to run
  script and ask the user if they trust the template.  We might even give the user an option to open the script in an editor so they can see what
  it wants to do.  One issue with these `<script>` directives is idempotency.  It is not uncommon that a user might want to run the template again
  for the same output directory.  The script needs to be "smart" about that and warn the user when it detects a `conflict` with an existing file.
  The user can then chose to allow the existing file to be overwritten or not.

  This approach should eliminate arbitrary code execution but we will need to provide a set of predefined variables.  Looking at
  [VSIX list of template parameters](https://msdn.microsoft.com/en-us/library/eehb4faa.aspx) gives a good idea of what we might want to predefine.
  On the positive side, we wouldn't need to resort to constrained runspace / restricted language mode.  These variables need to be in a
  different "namespace" than template-defined parameters.  Predefined variables are named like e.g `${PLASTER_<variable-name>}` and template-defined
  parameters are named like `${PLASTER_PARAM_<parameter-name>}`

  The use of "PowerShell" syntax works pretty well for specifying attribute values in the plasterManifest.xml file.  One exception is with
  `choice label` attributes.  You specify something like `&Yes` where the `&` indicates the shortcut character.  Unfortunately that isn't
  legal XML so you have to use `&amp;Yes`.  Not a big deal but not ideal.  The nice thing about using PowerShell syntax is that A)
  user's know it and B) it handles delineation between the variable identifier and subsequent text e.g.
  `destination='${PLASTER_PARAM_ModuleName}.psm1'`.

  The other place for variable substituion is within content files.  Using PowerShell syntax for template variable substitution inside a PS1
  file will be a bit trickier because the syntax is valid PowerShell syntax.  What we are using right now is `<%=<expression>%>`.
  Right now our `ExpandString` function is limited to `StringConstantExpressionAst` and `VariableExpressionAst`.  We may need to allow
  `BinaryExpressionAst` with the previous two types on both sides and operator `Format` e.g. `<%="{0:yyyy-MM-dd}" -f $PLASTER_DATETIME%>`.
- Condition support.  The template author needs to "conditionally" apply a template directive based on input from the user.
  Perhaps there is a template parameter that requires the user to answer the question "Do you want a PSake build script?".  Based on the
  user's response (or argument value passed to Invoke-Plaster) the template will execute a directive (or not) e.g.:
  ```xml
  <file source='build.ps1'
        destination='build.ps1'
        condition='$PLASTER_PARAM_Options -contains "PSake"'/>
  ```
  This requires execution of an expression.  **ISSUE: How do we do this but remain safe and not allow arbitrary code execution?**  Another (constrained) runspace?

## Concepts

### Template

The core concept for the model.  Can be a template for a single file or a complete directory structure.

## Cmdlets

### Invoke-Plaster

Provides the core functionality for creating a new project artifact from an existing template file.
Current parameters are TemplatePath, DestinationPath.  Eventually will add TemplateZipPath to point
to a ZIP file instead of an uncompressed template directory.

This command will also have dynamic parameters that correspond to the template parameters defined in
the PlasterManifest file.  For instance, given these parameters:
```xml
    <parameters>
        <parameter name='ModuleName' type='text' required='true' prompt='Enter the name of the module'/>
        <parameter name='Version' type='text' default='1.0.0' prompt='Enter the version number for the module'/>
        <parameter name='FullName' type='text' required='true' store='encrypt' prompt='Enter your fullname'/>
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
        <parameter name='Editor' type='choice' default='2' store='text' prompt='Which editor do you use'>
            <choice label='&amp;ISE'
                    help="Your editor is PowerShell ISE."
                    value="ISE"/>
            <choice label='Visual Studio &amp;Code'
                    help="Your editor is Visual Studio Code."
                    value="VSCode"/>
            <choice label='&amp;None'
                    help="No editor specified."
                    value="None"/>
        </parameter>
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

#### Items from Keith to integrate:

Musts:

1. DONE: Copy pre-created directories and files into a specified location.
2. DONE: Prompt user (either UI or via command line parameter) to supply information required by the template e.g. ModuleName, Author, etc.
3. Rename directories and files based on required input from user e.g. ModuleName
4. DONE: Replace substitution variables inside file content with input gathered from user e.g.
   contents of MyModule.Tests.ps1: `$ManifestName = '<%=${PLASTER_PARAM_ModuleName}.psd1%>'` => `$ManifestName = 'FooModule.psd1'`
5. IN-PROGRESS: Run PowerShell commands as part of “file generation”.  I don’t think we should ship a canned module manifest file.  We should use
   the New-ModuleManifest command to generate a manifest.  That way, we don’t have to stay in sync if new fields get added by that
   command.  That does mean that in the template metadata, we will need to be able to specify command name, parameters and map user
   input variables like ModuleName, Author to parameters to the command.
6. Advertise to environments (console, ISE, VSCode) templates that are suited for that environment.  In ISE I would not want to be
   offered a template that created a .vscode directory.
7. Support users ability to modify an existing template pkg and have it get picked up by environments like ISE and VSCode.

Wants:

1. Supply as a single file/pkg (probably a zip file).  This might not be important if we distribute using a PS module via the
   PSGallery.  Publishing the module will package into a single nupkg file and installing the module will extract the contents of the nupkg.
2. Metadata for template author.
3. Command to generate a blank template.
4. Command to pack template into that single template pkg file.

## Pushed to a Later Release

### Template Dependencies

Provides additional template generation behavior on top of the base template.  Can be used for optional template parts or
for editor-specific template files.  Can we do composition via dependencies?  Have template C require that templates A and
B be laid down first?

### Arbitrary Code Execution
I believe there is a need for an eventual `<script>` directive but I would like to wait until after the first version ships
and folks have a chance to use it and grok what Plaster is.  As Solomon Hykes, founder of Docker, has said about open source
development _"Rule #1 - no is temporary, yes is forever"_.
