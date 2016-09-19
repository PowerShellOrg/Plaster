##############################################################################
# PREVIEW VERSION OF PSAKE SCRIPT FOR MODULE BUILD & PUBLISH TO THE PSGALLERY
##############################################################################
#
# We are hoping to add support for publishing modules to the PowerShell gallery
# and private repositories in a future release of this extension.  This is an
# early look at the approach we are considering which is to supply a
# PSake-based script that will:
#
# 1. Create a directory from which to publish your module.
# 2. Copy the appropriate module files to that directory excluding items like
#    the .vscode directory, Pester tests, etc. These are configurable in Build.ps1.
# 3. Verify all existing Pester tests pass.
# 4. Publish the module to the desired repository (defaulting to the PSGallery).
#
# Requirements: PSake.  If you don't have this module installed use the following
# command to install it:
#
# PS C:\> Install-Module PSake -Scope CurrentUser
#
##############################################################################
# This is a PSake script that supports the following tasks:
# clean, build, test and publish.  The default task is build.
#
# The publish task uses the Publish-Module command to publish
# to either the PowerShell Gallery (the default) or you can change
# the $Repository property to the name of an alternate repository.
#
# The test task invokes Pester to run any Pester tests in your
# workspace folder. Name your test scripts <TestName>.Tests.ps1
# and Pester will find and run the tests contained in the files.
#
# You can run this build script directly using the invoke-psake
# command which will execute the build task.  This task "builds"
# a temporary folder from which the module can be published.
#
# PS C:\> invoke-psake build.psake.ps1
#
# You can run your Pester tests (if any) by running the following command.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList test
#
# You can execute the publish task with the following command. Note that
# the publish task will run the test task first. The Pester tests must pass
# before the publish task will run.  The first time you run the publish
# command, you will be prompted to enter your PowerShell Gallery NuGetApiKey.
# After entering the key, it is encrypted and stored so you will not have to
# enter it again.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList publish
#
# You can verify the stored and encrypted NuGetApiKey by running the following
# command. This will display your NuGetApiKey in plain text!
#
# PS C:\> invoke-psake build.psake.ps1 -taskList showApiKey
#
# You can store a new NuGetApiKey with this command. You can leave off
# the -properties parameter and you'll be prompted for the key.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList storeApiKey -properties @{NuGetApiKey='test123'}
#


###############################################################################
# Customize these properties for your module.
###############################################################################

Properties {
    # ----------------------- Basic properties --------------------------------

    # The root directory of the module source and tests.  It could be the workspace
    # root or a subdir such as src, module, <my-module-name>.
    $SourceRootDir = "$PSScriptRoot/src"
    $TestRootDir   = "$PSScriptRoot/test"

    # -------------------- Publishing properties ------------------------------

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    # The contents of this file are used during publishing for the ReleaseNotes parameter.
    $ReleaseNotesPath = "$PSScriptRoot/ReleaseNotes.md"

    # Set to $true if you want to sign your scripts. You will need to have a code-signing certificate.
    # You can specify the certificate's subject name below. If not specified, you will be prompted to
    # provide either a subject name or path to a PFX file.  After this one time prompt, the value will
    # saved for future use and you will no longer be prompted.
    $SignScripts = $false

    # Specify the Subject Name of the certificate used to sign your scripts.  Leave it as $null and the
    # first time you build, you will be prompted to enter your API key. This variable is used only if
    # $SignScripts is set to $true.  This does require the code-signing certificate to be installed
    # to your certificate store.  If you have a code-signing certificate in a PFX file, install the
    # certificate to your certificate store with the command below. You may be prompted for the
    # certificate's password.
    #
    # Import-PfxCertificate -FilePath .\myCodeSigingCert.pfx -CertStoreLocation Cert:\CurrentUser\My
    $CertSubjectName = $null

    # Your NuGet API key for the PSGallery.  Leave it as $null and the first time
    # you publish, you will be prompted to enter your API key.  The build will
    # store the key encrypted in the settings file, so that on subsequent
    # publishes you will no longer be prompted for the API key.
    $NuGetApiKey = $null

    # Name of the repository you wish to publish to. Default repo is the PowerShellGallery.
    $PublishRepository = $null

    # ----------------------- Misc properties ---------------------------------

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter. PFX passwords will not be stored.
    $SettingsPath = "$env:LOCALAPPDATA\Plaster\NewModuleTemplate\SecuredBuildSettings.clixml"

    # The name of your module should match the basename of the PSD1 file.
    $ModuleName = (Get-Item $SourceRootDir/*.psd1 |
                   Foreach-Object {$null = Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue; if ($?) { $_ }})[0].BaseName

    # The directory used to publish the module from.  If you are using Git, the
    # $PublishRootDir should be ignored if it is under the workspace directory.
    $PublishRootDir = "$PSScriptRoot\.publish"
    $PublishDir     = "$PublishRootDir\$ModuleName"

    # The local installation directory for the install task. Defaults to your user PSModulePath.
    $InstallPath = "$($($env:PSModulePath).Split(';')[0])\$ModuleName"

    # The following items will not be copied to the $PublishDir. Typically you
    # wouldn't put any file under the src dir unless the file was going to ship with
    # the module. However, if there are such files, add them to the exclude list below.
    $Exclude = @()
}

###############################################################################
# Customize these tasks for performing operations before and/or after publish.
###############################################################################

# Executes before src is copied to publish dir
Task PreCopySource {
}

# Executes after src is copied to publish dir
Task PostCopySource {
}

# Executes before publishing occurs.
Task PrePublish {
}

# Executes after publishing occurs.
Task PostPublish {
}


###############################################################################
# Core task implementations
###############################################################################
Task default -depends Build

Task Init -requiredVariables PublishDir {
    if (!(Test-Path $PublishDir) -and $PublishDir.StartsWith($PSScriptRoot, 'OrdinalIgnoreCase')) {
        New-Item $PublishDir -ItemType Directory > $null
    }
}

Task Clean -requiredVariables PublishRootDir {
    if ((Test-Path $PublishRootDir) -and $PublishRootDir.StartsWith($PSScriptRoot, 'OrdinalIgnoreCase')) {
        Get-ChildItem $PublishRootDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }
}

Task CopySource -depends Init, Clean -requiredVariables SourceRootDir, PublishDir {
    Copy-Item -Path $SourceRootDir -Destination $PublishDir -Recurse -Exclude $Exclude -Verbose:$VerbosePreference
}

Task Sign -depends CopySource -requiredVariables SettingsPath, SignScripts {
    if (!$SignScripts) {
        "Script signing is not enabled.  Skipping Sign task."
        return
    }

    $certSubjectNameKey = "CertSubjectName"
    $storeCertSubjectName = $true

    # Get the subject name of the code-signing certificate to be used for script signing.
    if (!$CertSubjectName -and ($CertSubjectName = GetSetting -Key $certSubjectNameKey -Path $SettingsPath)) {
        $storeCertSubjectName = $false
    }
    elseif (!$CertSubjectName) {
        $CertSubjectName = 'CN='
        $CertSubjectName += Read-Host -Prompt 'Enter the certificate subject name for script signing. Use exact casing, CN= prefix will be added'
    }
    elseif ($CertSubjectName -notmatch "^CN=") {
        $CertSubjectName = "CN=$CertSubjectName"
    }

    # Find a code-signing certificate that matches the specified subject name.
    $cert = Get-ChildItem -Path Cert:\ -CodeSigningCert -Recurse |
                Where-Object { $_.SubjectName.Name.StartsWith($CertSubjectName) -and $_.NotAfter -gt (Get-Date) } |
                Sort-Object -Property NotAfter -Descending | Select-Object -First 1

    if ($cert) {
        if ($storeCertSubjectName) {
            SetSetting -Key $certSubjectNameKey -Value $cert.SubjectName.Name -Path $SettingsPath
            "The new certificate subject name has been stored in ${SettingsPath}."
        }
        else {
            "Using stored certificate subject name $CertSubjectName from ${SettingsPath}."
        }

        $certificate = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
        "Using certificate $certificate to sign scripts."

        $files = @(Get-ChildItem -Path $PublishDir\* -Recurse -Include '*.ps1', '*.psm1')
        foreach ($file in $files) {
            $result = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $certificate -Verbose:$VerbosePreference
            if ($result.Status -ne 'Valid') {
                throw "Failed to sign script: $($file.FullName)."
            }

            "Successfully signed script: $($file.Name)"
        }
    }
    else {
        throw 'No valid certificate subject name supplied or stored.'
    }
}

Task Install -depends Test {
    if (-not (Test-Path -Path $InstallPath)) {
        Write-Verbose -Message 'Creating local install directory'
        New-Item -Path $InstallPath -ItemType Directory -Verbose:$VerbosePreference | Out-Null
    }

    Copy-Item -Path "$PublishDir\*" -Destination $InstallPath -Verbose:$VerbosePreference -Recurse -Force
}

Task Build -depends PreCopySource, CopySource, PostCopySource, Sign {
}

Task Test -depends Build {
    Import-Module Pester
    try {
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $TestRootDir
        Invoke-Pester
    }
    finally {
        Microsoft.PowerShell.Management\Pop-Location
    }
}

Task Publish -depends Test, PrePublish, PublishImpl, PostPublish {
}

Task PublishImpl -depends Test -requiredVariables SettingsPath, PublishDir {
    $publishParams = @{
        Path        = $PublishDir
        NuGetApiKey = $NuGetApiKey
    }

    # Publishing to the PSGallery requires an API key, so get it.
    if ($NuGetApiKey) {
        "Using script embedded NuGetApiKey"
    }
    elseif ($NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        "Using stored NuGetApiKey"
    }
    else {
        $promptForKeyCredParams = @{
            DestinationPath = $SettingsPath
            Message         = 'Enter your NuGet API key in the password field'
            Key             = 'NuGetApiKey'
        }

        $cred = PromptUserForCredentialAndStorePassword @promptForKeyCredParams
        $NuGetApiKey = $cred.GetNetworkCredential().Password
        "The NuGetApiKey has been stored in $SettingsPath"
    }

    $publishParams = @{
        Path        = $PublishDir
        NuGetApiKey = $NuGetApiKey
    }

    # If an alternate repository is specified, set the appropriate parameter.
    if ($PublishRepository) {
        $publishParams['Repository'] = $PublishRepository
    }

    # Consider not using -ReleaseNotes parameter when Update-ModuleManifest has been fixed.
    if ($ReleaseNotesPath) {
        $publishParams['ReleaseNotes'] = @(Get-Content $ReleaseNotesPath)
    }

    "Calling Publish-Module..."
    # TODO: Remove the -WhatIf before finalizing this
    Publish-Module @publishParams -WhatIf
}


###############################################################################
# Secondary/utility tasks - typically used to manage stored build settings.
###############################################################################

Task ? -description 'Lists the available tasks' {
    "Available tasks:"
    $PSake.Context.Peek().Tasks.Keys | Sort-Object
}

Task RemoveApiKey -requiredVariables SettingsPath {
    if (GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        RemoveSetting -Path $SettingsPath -Key NuGetApiKey
    }
}

Task StoreApiKey -requiredVariables SettingsPath {
    $promptForKeyCredParams = @{
        DestinationPath = $SettingsPath
        Message         = 'Enter your NuGet API key in the password field'
        Key             = 'NuGetApiKey'
    }

    PromptUserForCredentialAndStorePassword @promptForKeyCredParams
    "The NuGetApiKey has been stored in $SettingsPath"
}

Task ShowApiKey -requiredVariables SettingsPath {
    $OFS = ""
    if ($NuGetApiKey) {
        "The embedded (partial) NuGetApiKey is: $($NuGetApiKey[0..7])"
    }
    elseif ($NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        "The stored (partial) NuGetApiKey is: $($NuGetApiKey[0..7])"
    }
    else {
        "The NuGetApiKey has not been provided or stored."
        return
    }

    "To see the full key, use the task 'ShowFullApiKey'"
}

Task ShowFullApiKey -requiredVariables SettingsPath {
    if ($NuGetApiKey) {
        "The embedded NuGetApiKey is: $NuGetApiKey"
    }
    elseif ($NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        "The stored NuGetApiKey is: $NuGetApiKey"
    }
    else {
        "The NuGetApiKey has not been provided or stored."
    }
}

Task RemoveCertSubjectName -requiredVariables SettingsPath {
    if (GetSetting -Path $SettingsPath -Key CertSubjectName) {
        RemoveSetting -Path $SettingsPath -Key CertSubjectName
    }
}

Task StoreCertSubjectName -requiredVariables SettingsPath {
    $certSubjectName = 'CN='
    $certSubjectName += Read-Host -Prompt 'Enter the certificate subject name for script signing. Use exact casing, CN= prefix will be added'
    SetSetting -Key CertSubjectName -Value $certSubjectName -Path $SettingsPath
    "The new certificate subject name '$certSubjectName' has been stored in ${SettingsPath}."
}

Task ShowCertSubjectName -requiredVariables SettingsPath {
    $CertSubjectName = GetSetting -Path $SettingsPath -Key CertSubjectName
    "The stored certificate is: $CertSubjectName"

    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
            Where-Object { $_.Subject -eq $CertSubjectName -and $_.NotAfter -gt (Get-Date) } |
            Sort-Object -Property NotAfter -Descending | Select-Object -First 1

    if ($cert) {
        "A valid certificate for the subject $CertSubjectName has been found"
    }
    else {
        'A valid certificate has not been found'
    }
}


###############################################################################
# Helper functions
###############################################################################

function PromptUserForCredentialAndStorePassword {
    [Diagnostics.CodeAnalysis.SuppressMessage("PSProvideDefaultParameterValue", '')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath,

        [Parameter(Mandatory)]
        [string]
        $Message,

        [Parameter(Mandatory, ParameterSetName = 'SaveSetting')]
        [string]
        $Key
    )

    $cred = Get-Credential -Message $Message -UserName "ignored"
    if ($DestinationPath) {
        SetSetting -Key $Key -Value $cred.Password -Path $DestinationPath
    }

    $cred
}

function AddSetting {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Value
    )

    switch ($type = $Value.GetType().Name) {
        'securestring' { $setting = $Value | ConvertFrom-SecureString }
        default        { $setting = $Value }
    }

    if (Test-Path -LiteralPath $Path) {
        $storedSettings = Import-Clixml -Path $Path
        $storedSettings.Add($Key, @($type, $setting))
        $storedSettings | Export-Clixml -Path $Path
    }
    else {
        $parentDir = Split-Path -Path $Path -Parent
        if (!(Test-Path -LiteralPath $parentDir)) {
            New-Item $parentDir -ItemType Directory > $null
        }

        @{$Key = @($type, $setting)} | Export-Clixml -Path $Path
    }
}

function GetSetting {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        $securedSettings = Import-Clixml -Path $Path
        if ($securedSettings.$Key) {
            switch ($securedSettings.$Key[0]) {
                'securestring' {
                    $value = $securedSettings.$Key[1] | ConvertTo-SecureString
                    $cred = New-Object -TypeName PSCredential -ArgumentList 'jpgr', $value
                    $cred.GetNetworkCredential().Password
                }
                default {
                    $securedSettings.$Key[1]
                }
            }
        }
    }
}

function SetSetting {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Value
    )

    if (GetSetting -Key $Key -Path $Path) {
        RemoveSetting -Key $Key -Path $Path
    }

    AddSetting -Key $Key -Value $Value -Path $Path
}

function RemoveSetting {
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        $storedSettings = Import-Clixml -Path $Path
        $storedSettings.Remove($Key)
        if ($storedSettings.Count -eq 0) {
            Remove-Item -Path $Path
        }
        else {
            $storedSettings | Export-Clixml -Path $Path
        }
    }
    else {
        Write-Warning "The build setting file '$Path' has not been created yet."
    }
}
