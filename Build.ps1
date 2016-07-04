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
# PS C:\> invoke-psake build.ps1
#
# You can run your Pester tests (if any) by running the following command.
#
# PS C:\> invoke-psake build.ps1 -taskList test
#
# You can execute the publish task with the following command. Note that
# the publish task will run the test task first. The Pester tests must pass
# before the publish task will run.  The first time you run the publish
# command, you will be prompted to enter your PowerShell Gallery NuGetApiKey.
# After entering the key, it is encrypted and stored so you will not have to
# enter it again.
#
# PS C:\> invoke-psake build.ps1 -taskList publish
#
# You can verify the stored and encrypted NuGetApiKey by running the following
# command. This will display your NuGetApiKey in plain text!
#
# PS C:\> invoke-psake build.ps1 -taskList showKey
#
# You can store a new NuGetApiKey with this command. You can leave off
# the -properties parameter and you'll be prompted for the key.
#
# PS C:\> invoke-psake build.ps1 -taskList storeKey -properties @{NuGetApiKey='test123'}
#

###############################################################################
# Customize these properties for your module.
###############################################################################
Properties {
    # The name of your module should match the basename of the PSD1 file.
    $ModuleName = (Get-Item $PSScriptRoot\*.psd1 |
                   Foreach-Object {$null = Test-ModuleManifest -Path $_ -ErrorAction SilentlyContinue; if ($?) {$_}})[0].BaseName

    # Path to the release notes file.  Set to $null if the release notes reside in the manifest file.
    $ReleaseNotesPath = "$PSScriptRoot\ReleaseNotes.md"

    # The directory used to publish the module from.  If you are using Git, the
    # $PublishRootDir should be ignored if it is under the workspace directory.
    $PublishRootDir = "$PSScriptRoot\Release"
    $PublishDir     = "$PublishRootDir\$ModuleName"

    # The following items will not be copied to the $PublishDir.
    # Add items that should not be published with the module.
    $Exclude = @(
        (Split-Path $PSCommandPath -Leaf),
        'Release',
        'Tests',
        '.git*',
        '.vscode',
        # These files are unique to this examples dir.
        'DebugTest.ps1',
        'PSScriptAnalyzerSettings.psd1',
        'Readme.md',
        'Stop*.ps1'
    )

    # Name of the repository you wish to publish to. Default repo is the PSGallery.
    $PublishRepository = $null

    # Your NuGet API key for the PSGallery.  Leave it as $null and the first time
    # you publish you will be prompted to enter your API key.  The build will
    # store the key encrypted in a file, so that on subsequent publishes you
    # will no longer be prompted for the API key.
    $NuGetApiKey = $null

    # If you specify the certificate subject when running a build that certificate 
    # must exist in the users personal certificate store. The build will import the 
    # certificate (if required), then store the subject, so that on subsequent 
    # signing the build will use the same (or newer) certificate with that subject.
    $CertSubject = $null

    # In addition, PFX certificates are supported in an interactive scenario only,
    # as a way to import a certificate into the user personal store for later use.
    # This can be provided using the CertPfxPath parameter.
    # PFX passwords will not be stored.
    $SettingsPath = "$env:LOCALAPPDATA\WindowsPowerShell\SecuredSettings.clixml"
}

###############################################################################
# Customize these tasks for performing operations before and/or after publish.
###############################################################################
Task PrePublish {
}

Task PostPublish {
}

###############################################################################
# Core task implementations - this possibly "could" ship as part of the
# vscode-powershell extension and then get dot sourced into this file.
###############################################################################
Task default -depends Build

Task Publish -depends Test, PrePublish, PublishImpl, PostPublish {
}

Task PublishImpl -depends Test -requiredVariables SettingsPath, PublishDir {
    if ($NuGetApiKey) {
        "Using script embedded NuGetApiKey"
    }
    elseif (GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        $NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey
        "Using stored NuGetApiKey"
    }
    else {
        $KeyCred = @{
            DestinationPath = $SettingsPath
            Message         = 'Enter your NuGet API key in the password field'
            Key             = 'NuGetApiKey'
        }
        $cred = PromptUserForKeyCredential @KeyCred
        $NuGetApiKey = $cred.GetNetworkCredential().Password
        "The NuGetApiKey has been stored in $SettingsPath"
    }

    $publishParams = @{
        Path        = $PublishDir
        NuGetApiKey = $NuGetApiKey
    }

    if ($PublishRepository) {
        $publishParams['Repository'] = $PublishRepository
    }

    # Consider not using -ReleaseNotes parameter when Update-ModuleManifest has been fixed.
    if ($ReleaseNotesPath) {
        $publishParams['ReleaseNotes'] = @(Get-Content $ReleaseNotesPath)
    }

    "Calling Publish-Module..."
    Publish-Module @publishParams -WhatIf
}

Task Test -depends Build {
    Import-Module Pester
    Invoke-Pester $PSScriptRoot
}

Task Build -depends Clean, Init -requiredVariables PublishDir, Exclude, ModuleName {
    Copy-Item -Path $PSScriptRoot\* -Destination $PublishDir -Recurse -Exclude $Exclude

    # Get contents of the ReleaseNotes file and update the copied module manifest file
    # with the release notes.
    # DO NOT USE UNTIL UPDATE-MODULEMANIFEST IS FIXED - DOES NOT HANDLE SINGLE QUOTES CORRECTLY.
    # if ($ReleaseNotesPath) {
    #     $releaseNotes = @(Get-Content $ReleaseNotesPath)
    #     Update-ModuleManifest -Path $PublishDir\${ModuleName}.psd1 -ReleaseNotes $releaseNotes
    # }
}

Task Clean -requiredVariables PublishRootDir {
    # Sanity check the dir we are about to "clean".  If $PublishRootDir were to
    # inadvertently get set to $null, the Remove-Item commmand removes the
    # contents of \*.  That's a bad day.  Ask me how I know?  :-(
    if ((Test-Path $PublishRootDir) -and $PublishRootDir.Contains($PSScriptRoot)) {
        Remove-Item $PublishRootDir\* -Recurse -Force
    }
}

Task Init -requiredVariables PublishDir {
    if (!(Test-Path $PublishDir)) {
        $null = New-Item $PublishDir -ItemType Directory
    }
}

Task RemoveKey -requiredVariables SettingsPath {
    if (GetSetting -Path $SettingsPath -Key NuGetApiKey) {
        RemoveSetting -Path $SettingsPath -Key NuGetApiKey
    }
}

Task StoreKey -requiredVariables SettingsPath {
    $KeyCred = @{
        DestinationPath = $SettingsPath
        Message         = 'Enter your NuGet API key in the password field'
        Key             = 'NuGetApiKey'
    }
    PromptUserForKeyCredential @KeyCred
    "The NuGetApiKey has been stored in $SettingsPath"
}

Task ShowKey -requiredVariables SettingsPath {
    if ($NuGetApiKey) {
        "The embedded (partial) NuGetApiKey is: $($NuGetApiKey[0..7])"
    }
    else {
        $NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey
        "The stored (partial) NuGetApiKey is: $($NuGetApiKey[0..7])"
    }
    Write-Output "To see the full key, use the task 'ShowFullKey'"
}

Task ShowFullKey -requiredVariables SettingsPath {
    if ($NuGetApiKey) {
        "The embedded NuGetApiKey is: $NuGetApiKey"
    }
    else {
        $NuGetApiKey = GetSetting -Path $SettingsPath -Key NuGetApiKey
        "The stored NuGetApiKey is: $NuGetApiKey"
    }
}

Task ? -description 'Lists the available tasks' {
    "Available tasks:"
    $PSake.Context.Peek().Tasks.Keys | Sort-Object
}

Task Sign -depends Test -requiredVariables SettingsPath {
    if ($CertPfxPath) {
        $CertImport = @{
            CertStoreLocation = 'Cert:\CurrentUser\My'
            FilePath          = $CertPfxPath
            Password          = $(PromptUserForKeyCredential -Message 'Enter the PFX password to import the certificate').Password
            ErrorAction       = 'Stop'
        }

        $Cert = Import-PfxCertificate @CertImport -Verbose:$VerbosePreference
    }
    else {
        if ($CertSubject -eq $null -and (GetSetting -Key CertSubject -Path $SettingsPath)) {
            $CertSubject = GetSetting -Key CertSubject -Path $SettingsPath
            $LoadedFromSubjectFile = $true
        }
        else {
            $CertSubject = 'CN='
            $CertSubject += Read-Host -Prompt 'Enter the certificate subject you wish to use (CN= prefix will be added)'
        }
        
        $Cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
            Where-Object { $_.Subject -eq $CertSubject -and $_.NotAfter -gt (Get-Date) } |
            Sort-Object -Property NotAfter -Descending | Select-Object -First 1
    }
    
    if ($Cert) {
        if (-not $LoadedFromSubjectFile) {
            SetSetting -Key CertSubject -Value $Cert.Subject -Path $SettingsPath
            Write-Output "The new certificate subject has been stored in $SettingsPath"
        }
        else {
            Write-Output "Using stored certificate subject $CertSubject from $SettingsPath"
        }

        $Authenticode   = @{
            FilePath    = @(Get-ChildItem -Path "$PublishDir\*" -Recurse -Include '*.ps1', '*.psm1')
            Certificate = Get-ChildItem Cert:\CurrentUser\My |
                Where-Object { $_.Thumbprint -eq $Cert.Thumbprint }
        }

        Write-Output -InputObject $Authenticode.FilePath | Out-Default
        Write-Output -InputObject $Authenticode.Certificate | Out-Default
        $SignResult = Set-AuthenticodeSignature @Authenticode -Verbose:$VerbosePreference
        if ($SignResult.Status -ne 'Valid') {
            throw "Signing one or more scripts failed."
        }
    }
    else {
        throw 'No valid certificate subject supplied or stored.'
    }
}

Task RemoveCertSubject -requiredVariables SettingsPath {
    if (GetSetting -Path $SettingsPath -Key CertSubject) {
        RemoveSetting -Path $SettingsPath -Key CertSubject
    }
}

Task ShowCertSubject -requiredVariables SettingsPath {
    $CertSubject = GetSetting -Path $SettingsPath -Key CertSubject
    Write-Output "The stored certificate is: $CertSubject"
    $Cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
            Where-Object { $_.Subject -eq $CertSubject -and $_.NotAfter -gt (Get-Date) } |
            Sort-Object -Property NotAfter -Descending | Select-Object -First 1

    if ($Cert) {
        Write-Output "A valid certificate for the subject $CertSubject has been found"
    }

    else {
        Write-Output 'A valid certificate has not been found'
    }
}

Task BuildSigned -depends Sign, Build {}

Task PublishSigned -depends Sign, Publish {}

###############################################################################
# Helper functions
###############################################################################
function PromptUserForKeyCredential {
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

    $KeyCred = Get-Credential -Message $Message -UserName "ignored"
    if ($DestinationPath) {
        SetSetting -Key $Key -Value $KeyCred.Password -Path $DestinationPath
    }

    $KeyCred
}

function AddSetting {
    Param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Value
    )

    switch ($Type = $Value.GetType().Name) {
        'securestring' {
            $Setting = $Value | ConvertFrom-SecureString
        }
        default {
            $Setting = $Value
        }
    }

    if (Test-Path -Path $Path) {
        $StoredSettings = Import-Clixml -Path $Path
        $StoredSettings.Add($Key, @($Type, $Setting))
        $StoredSettings | Export-Clixml -Path $Path
    }
    else {
        @{$Key = @($Type, $Setting)} | Export-Clixml -Path $Path
    }
}

function GetSetting {
    Param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        $SecuredSettings = Import-Clixml -Path $Path
        if ($SecuredSettings.$Key) {
            switch ($SecuredSettings.$Key[0]) {
                'securestring' {
                    $Value = $SecuredSettings.$Key[1] | ConvertTo-SecureString
                    $cred = New-Object -TypeName PSCredential -ArgumentList 'jpgr', $Value
                    $cred.GetNetworkCredential().Password
                }
                default {
                    $SecuredSettings.$Key[1]
                }
            }
        }
    }
}

function SetSetting {
    Param(
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
    Param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $StoredSettings = Import-Clixml -Path $Path
    $StoredSettings.Remove($Key)
    if ($StoredSettings.Count -eq 0) {
        Remove-Item -Path $Path
    }
    else {
        $StoredSettings | Export-Clixml -Path $Path
    }
}