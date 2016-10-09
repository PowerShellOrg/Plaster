#Requires -Modules psake

##############################################################################
# DO NOT MODIFY THIS FILE!  Modify build.settings.ps1 instead.
##############################################################################

##############################################################################
# This is the PowerShell Module psake build script. It defines the following tasks:
#
# Clean, Build, Sign, BuildHelp, Install, Test and Publish.
#
# The default task is Build.  This task copies the appropriate files from the
# $SrcRootDir to the $OutDir.  Later, other tasks such as Sign and BuildHelp
# will further modify the contents of $OutDir and add new files.
#
# The Sign task will only sign scripts if the $SignScripts variable is set to
# $true.  A code-signing certificate is required for this task to complete.
#
# The BuildHelp task invokes platyPS to generate markdown files from
# comment-based help for your exported commands.  platyPS then generates
# a help file for your module from the markdown files.
#
# The Install task simplies copies the $OutDir to your profile's Modules folder.
#
# The Test task invokes Pester on the $TestRootDir.
#
# The Publish task uses the Publish-Module command to publish
# to either the PowerShell Gallery (the default) or you can change
# the $PublishRepository property to the name of an alternate repository.
# Note: the Publish task requires that the Test task execute without failures.
#
# You can exeute a specific task, such as the Test task by running the
# following command:
#
# PS C:\> invoke-psake build.psake.ps1 -taskList Test
#
# You can execute the Publish task with the following command.
# The first time you execute the Publish task, you will be prompted to enter
# your PowerShell Gallery NuGetApiKey.  After entering the key, it is encrypted
# and stored so you will not have to enter it again.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList Publish
#
# You can verify the stored and encrypted NuGetApiKey by running the following
# command which will display a portion of your NuGetApiKey in plain text.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList ShowApiKey
#
# You can store a new NuGetApiKey with this command. You can leave off
# the -properties parameter and you'll be prompted for the key.
#
# PS C:\> invoke-psake build.psake.ps1 -taskList StoreApiKey -properties @{NuGetApiKey='test123'}
#

###############################################################################
# Dot source the user's customized properties and extension tasks.
###############################################################################
. $PSScriptRoot\build.settings.ps1

###############################################################################
# Core task implementations. Avoid modifying these tasks.
###############################################################################
Task default -depends Build

Task Init -requiredVariables OutDir {
    if (!(Test-Path $OutDir) -and $OutDir.StartsWith($PSScriptRoot, 'OrdinalIgnoreCase')) {
        New-Item $OutDir -ItemType Directory > $null
    }
}

Task Clean -requiredVariables ReleaseDir {
    if ((Test-Path $ReleaseDir) -and $ReleaseDir.StartsWith($PSScriptRoot, 'OrdinalIgnoreCase')) {
        Get-ChildItem $ReleaseDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }
}

Task Build -depends BuildImpl, Analyze, Sign, PostBuild {
}

Task BuildImpl -depends Init, Clean, PreBuild -requiredVariables SrcRootDir, OutDir {
    Copy-Item -Path $SrcRootDir -Destination $OutDir -Recurse -Exclude $Exclude -Verbose:$VerbosePreference
}

Task Analyze -depends BuildImpl -requiredVariables ScriptAnalysisAction, OutDir {
    if ((Get-Host).Name -in $SkipScriptAnalysisHost) {
        $ScriptAnalysisAction = 'Skip'
    }

    if (!(Get-Module PSScriptAnalyzer -ListAvailable)) {
        "Script Analyzer nodule is not installed.  Skipping Analyze task."
        return
    }

    if ($ScriptAnalysisAction -eq 'Skip') {
        "Script analysis is not enabled.  Skipping Analyze task."
        return
    }

    $analysisResult = Invoke-ScriptAnalyzer -Path $OutDir -Settings $ScriptAnalysisSettingsPath -Recurse -Verbose:$VerbosePreference
    $analysisResult | Format-Table
    switch ($ScriptAnalysisAction) {
        'Error' {
            Assert -conditionToCheck (
                ($analysisResult | Where-Object Severity -eq 'Error').Count -eq 0
                ) -failureMessage 'One or more Script Analyzer errors were found. Build cannot continue!'
        }
        'Warning' {
            Assert -conditionToCheck (
                ($analysisResult | Where-Object {
                    $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error'
                }).Count -eq 0) -failureMessage 'One or more Script Analyzer warnings were found. Build cannot continue!'
        }
        'None' {
            return
        }
        default {
            Assert -conditionToCheck (
                $analysisResult.Count -eq 0
                ) -failureMessage 'One or more Script Analyzer issues were found. Build cannot continue!'
        }
    }
}

Task Sign -depends BuildImpl -requiredVariables SettingsPath, SignScripts {
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
                Where-Object { $_.SubjectName.Name.StartsWith($CertSubjectName) -and ($_.NotAfter -ge (Get-Date)) } |
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
        "Using code-signing certificate: $certificate"

        $files = @(Get-ChildItem -Path $OutDir\* -Recurse -Include *.ps1,*.psm1)
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

Task GenerateMarkdown -depends Build, PreBuildHelp -requiredVariables DocsRootDir, ModuleName, OutDir {
    if ($null -eq $DefaultLocale) {
        $DefaultLocale = 'en-US'
    }

    $moduleInfo = Import-Module $OutDir\$ModuleName.psd1 -Global -Force -PassThru
    if ($moduleInfo.ExportedCommands.Count -eq 0) {
        "No commands have been exported. Skipping GenerateDocs task."
        return
    }

    if (!(Test-Path -LiteralPath $DocsRootDir)) {
        New-Item $DocsRootDir -ItemType Directory > $null
    }

    if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse) {
        Get-ChildItem -LiteralPath $DocsRootDir -Directory | ForEach-Object {
            Update-MarkdownHelp -Path $_.FullName > $null
        }
    }

    New-MarkdownHelp -Module $ModuleName -Locale $DefaultLocale -OutputFolder $DocsRootDir\$DefaultLocale `
                     -WithModulePage -ErrorAction SilentlyContinue > $null

    Remove-Module $ModuleName
}

Task BuildHelp -depends BuildHelpImpl, PostBuildHelp {
}

Task BuildHelpImpl -depends GenerateMarkdown -requiredVariables DocsRootDir, OutDir {
    if (!(Test-Path -LiteralPath $DocsRootDir) -or !(Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse)) {
        "No markdown help files to process. Skipping BuildDocs task."
        return
    }

    foreach ($locale in (Get-ChildItem -Path $DocsRootDir -Directory).Name) {
        New-ExternalHelp -Path $DocsRootDir\$locale -OutputPath $OutDir\$locale -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

Task Install -depends InstallImpl, PostInstall {
}

Task InstallImpl -depends BuildHelp, PreInstall -requiredVariables OutDir {
    if ($null -eq $InstallPath) {
        # The default installation path is the current user's module path.
        $moduleInfo = Test-ModuleManifest -Path $SrcRootDir\$ModuleName.psd1
        $InstallPath = Join-Path -Path (Split-Path $profile.CurrentUserAllHosts -Parent) `
                                 -ChildPath "Modules\$ModuleName\$($moduleInfo.Version.ToString())"
    }

    if (!(Test-Path -Path $InstallPath)) {
        Write-Verbose 'Creating local install directory'
        New-Item -Path $InstallPath -ItemType Directory -Verbose:$VerbosePreference > $null
    }

    Copy-Item -Path $OutDir\* -Destination $InstallPath -Verbose:$VerbosePreference -Recurse -Force
}

Task Test -depends Analyze -requiredVariables TestRootDir, ModuleName {
    Import-Module Pester

    try {
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $TestRootDir

        if ($TestOutputFile) {
            $TestResult = Invoke-Pester -OutputFile $TestOutputFile -OutputFormat $TestOutputFormat -PassThru -Verbose:$VerbosePreference
        }
        else {
            $TestResult = Invoke-Pester -PassThru -Verbose:$VerbosePreference
        }

        Assert ($TestResult.FailedCount -eq 0) "One or more Pester tests failed, build cannot continue."
    }
    finally {
        Microsoft.PowerShell.Management\Pop-Location
        Remove-Module $ModuleName -ErrorAction SilentlyContinue
    }
}

Task Publish -depends Test, PrePublish, PublishImpl, PostPublish {
}

Task PublishImpl -requiredVariables SettingsPath, OutDir {
    $publishParams = @{
        Path        = $OutDir
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
        Path        = $OutDir
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
    Publish-Module @publishParams
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
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '', Scope='Function')]
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
