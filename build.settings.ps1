###############################################################################
# Customize these properties and tasks for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    # The root directories for the module's docs, src and test.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DocsRootDir = "$PSScriptRoot/docs"
    $SrcRootDir  = "$PSScriptRoot/src"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestRootDir = "$PSScriptRoot/test"

    # The name of your module should match the basename of the PSD1 file.
    $ModuleName = Get-Item $SrcRootDir/*.psd1 |
                      Where-Object { $null -ne (Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue) } |
                      Select-Object -First 1 | Foreach-Object BaseName

    # The $OutDir must match the ModuleName in order to support publishing the module.
    $ReleaseDir = "$PSScriptRoot/Release"
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $OutDir     = "$ReleaseDir/$ModuleName"

    # Default Locale used for documentation generatioon, defaults to en-US.
    # [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $DefaultLocale = $null

    # Items in the $Exclude array will not be copied to the $OutDir e.g. $Exclude = @('.gitattributes')
    # Typically you wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add their $SrcRootDir relative paths to the exclude list.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $Exclude = @()

    # -------------------- Script analysis properties ------------------------------

    # To control the failure of the build with specific script analyzer rule severities,
    # the CodeAnalysisStop variable can be used. The supported values for this variable are
    # 'Warning', 'Error', 'All', 'None' or 'ReportOnly'. Invalid input will stop on all rules.
    # 'None' will skip over the code analysis step all together.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalysisAction = 'Error'

    # Path to PowerShell Script Analyzer settings file.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ScriptAnalysisSettingsPath = "$PSScriptRoot\ScriptAnalyzerSettings.psd1"

    # The script analysis task step will run, unless your host is in the array defined below.
    # This allows you to control whether code analysis is executed, for hosts where script
    # analysis is included in the product.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SkipScriptAnalysisHost = @(
        'Visual Studio Code Host',
        'My Custom Host with scriptanalyzer support'
    )

    # ------------------- Testing properties ----------------------------------

    # You can specify a minimum code coverage percentage that must be reached in order
    # for the test task to pass. The code coverage test is not performed if
    # $CodeCoveragePercentage is 0. If $CodeCoveragePercentage is non-zero, but is not
    # reached, the build script will fail.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoveragePercentage = 0

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://github.com/pester/Pester/wiki/Code-Coverage.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CodeCoverageSelection = "$SrcRootDir\*.ps1"

    # ------------------- Script signing properties ---------------------------

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SignScripts = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your code-signing certificate's Subject Name.
    # This variable is used only if $SignScripts is set to $true.
    #
    # This does require the code-signing certificate to be installed to your certificate store.  If you
    # have a code-signing certificate in a PFX file, install the certificate to your certificate store
    # with the command below. You may be prompted for the certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    #
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertSubjectName = $null

    # Certificate store path.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $CertPath = "Cert:\"

    # -------------------- Publishing properties ------------------------------

    # Your NuGet API key for the PSGallery.  Leave it as $null and the first time you publish,
    # you will be prompted to enter your API key.  The build will store the key encrypted in the
    # settings file, so that on subsequent publishes you will no longer be prompted for the API key.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $NuGetApiKey = $null

    # Name of the repository you wish to publish to. If $null is specified the default repo (PowerShellGallery) is used.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $PublishRepository = $null

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ReleaseNotesPath = "$PSScriptRoot\ReleaseNotes.md"

    # ----------------------- Misc properties ---------------------------------

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\NewModuleTemplate\SecuredBuildSettings.clixml"

    # The local installation directory for the install task. Defaults to your user PSModulePath.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $InstallPath = $null

    # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
    # This is typically used to write out test results so that they can be sent to a CI
    # system like AppVeyor.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFile = $null

    # Specifies the test output format to use when the TestOutputFile property is given
    # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $TestOutputFormat = "NUnitXml"
}

###############################################################################
# Customize these tasks for performing operations before and/or after Build.
###############################################################################

# Executes before the BuildImpl phase of the Build task.
Task PreBuild {
}

# Executes after the Sign phase of the Build task.
Task PostBuild {
}

###############################################################################
# Customize these tasks for performing operations before and/or after BuildHelp.
###############################################################################

# Executes before the GenerateMarkdown phase of the BuildHelp task.
Task PreBuildHelp {
}

# Executes after the BuildHelpImpl phase of the BuildHelp task.
Task PostBuildHelp {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Install.
###############################################################################

# Executes before the InstallImpl phase of the Install task.
Task PreInstall {
}

# Executes after the InstallImpl phase of the Install task.
Task PostInstall {
}

###############################################################################
# Customize these tasks for performing operations before and/or after Publish.
###############################################################################

# Executes before publishing occurs.
Task PrePublish {
}

# Executes after publishing occurs.
Task PostPublish {
}
