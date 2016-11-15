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
# $SrcRootDir under the $OutDir.  Later, other tasks such as Sign and BuildHelp
# will further modify the contents of $OutDir and add new files.
#
# The Sign task will only sign scripts if the $SignScripts variable is set to
# $true.  A code-signing certificate is required for this task to complete.
#
# The BuildHelp task invokes platyPS to generate markdown files from
# comment-based help for your exported commands.  platyPS then generates
# a help file for your module from the markdown files.
#
# The Install task simplies copies the module folder under $OutDir to your
# profile's Modules folder.
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
# Private properties.
###############################################################################
Properties {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $ModuleOutDir = "$OutDir\$ModuleName"

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $UpdatableHelpOutDir = "$OutDir\UpdatableHelp"

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $SharedProperties = @{}

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
    $LineSep = "-" * 78
}

###############################################################################
# Core task implementations. Avoid modifying these tasks.
###############################################################################
Task default -depends Build

Task Init -requiredVariables OutDir {
    if (!(Test-Path -LiteralPath $OutDir)) {
        New-Item $OutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "$($psake.context.currentTaskName) - directory already exists '$OutDir'."
    }
}

Task Clean -depends Init -requiredVariables OutDir {
    # Maybe a bit paranoid but this task nuked \ on my laptop. Good thing I was not running as admin.
    if ($OutDir.Length -gt 3) {
        Get-ChildItem $OutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }
    else {
        Write-Verbose "$($psake.context.currentTaskName) - `$OutDir '$OutDir' must be longer than 3 characters."
    }
}

Task StageFiles -depends Init, Clean, BeforeStageFiles, CoreStageFiles, AfterStageFiles {
}

Task CoreStageFiles -requiredVariables ModuleOutDir, SrcRootDir {
    if (!(Test-Path -LiteralPath $ModuleOutDir)) {
        New-Item $ModuleOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "$($psake.context.currentTaskName) - directory already exists '$ModuleOutDir'."
    }

    Copy-Item -Path $SrcRootDir\* -Destination $ModuleOutDir -Recurse -Exclude $Exclude -Verbose:$VerbosePreference
}

Task Build -depends Init, Clean, BeforeBuild, StageFiles, Analyze, Sign, AfterBuild {
}

Task Analyze -depends StageFiles `
             -requiredVariables ModuleOutDir, ScriptAnalysisEnabled, ScriptAnalysisFailBuildOnSeverityLevel, ScriptAnalyzerSettingsPath {
    if (!$ScriptAnalysisEnabled) {
        "Script analysis is not enabled. Skipping $($psake.context.currentTaskName) task."
        return
    }

    if (!(Get-Module PSScriptAnalyzer -ListAvailable)) {
        "PSScriptAnalyzer module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    "ScriptAnalysisFailBuildOnSeverityLevel set to: $ScriptAnalysisFailBuildOnSeverityLevel"

    $analysisResult = Invoke-ScriptAnalyzer -Path $ModuleOutDir -Settings $ScriptAnalyzerSettingsPath -Recurse -Verbose:$VerbosePreference
    $analysisResult | Format-Table
    switch ($ScriptAnalysisFailBuildOnSeverityLevel) {
        'None' {
            return
        }
        'Error' {
            Assert -conditionToCheck (
                ($analysisResult | Where-Object Severity -eq 'Error').Count -eq 0
                ) -failureMessage 'One or more ScriptAnalyzer errors were found. Build cannot continue!'
        }
        'Warning' {
            Assert -conditionToCheck (
                ($analysisResult | Where-Object {
                    $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error'
                }).Count -eq 0) -failureMessage 'One or more ScriptAnalyzer warnings were found. Build cannot continue!'
        }
        default {
            Assert -conditionToCheck (
                $analysisResult.Count -eq 0
                ) -failureMessage 'One or more ScriptAnalyzer issues were found. Build cannot continue!'
        }
    }
}

Task Sign -depends StageFiles -requiredVariables CertPath, SettingsPath, ScriptSigningEnabled {
    if (!$ScriptSigningEnabled) {
        "Script signing is not enabled. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $validCodeSigningCerts = Get-ChildItem -Path $CertPath -CodeSigningCert -Recurse | Where-Object NotAfter -ge (Get-Date)
    if (!$validCodeSigningCerts) {
        throw "There are no non-expired code-signing certificates in $CertPath. You can either install " +
              "a code-signing certificate into the certificate store or disable script analysis in build.settings.ps1."
    }

    $certSubjectNameKey = "CertSubjectName"
    $storeCertSubjectName = $true

    # Get the subject name of the code-signing certificate to be used for script signing.
    if (!$CertSubjectName -and ($CertSubjectName = GetSetting -Key $certSubjectNameKey -Path $SettingsPath)) {
        $storeCertSubjectName = $false
    }
    elseif (!$CertSubjectName) {
        "A code-signing certificate has not been specified."
        "The following non-expired, code-signing certificates are available in your certificate store:"
        $validCodeSigningCerts | Format-List Subject,Issuer,Thumbprint,NotBefore,NotAfter

        $CertSubjectName = Read-Host -Prompt 'Enter the subject name (case-sensitive) of the certificate to use for script signing'
    }

    # Find a code-signing certificate that matches the specified subject name.
    $certificate = $validCodeSigningCerts |
                       Where-Object { $_.SubjectName.Name -cmatch [regex]::Escape($CertSubjectName) } |
                       Sort-Object NotAfter -Descending | Select-Object -First 1

    if ($certificate) {
        $SharedProperties.CodeSigningCertificate = $certificate

        if ($storeCertSubjectName) {
            SetSetting -Key $certSubjectNameKey -Value $certificate.SubjectName.Name -Path $SettingsPath
            "The new certificate subject name has been stored in ${SettingsPath}."
        }
        else {
            "Using stored certificate subject name $CertSubjectName from ${SettingsPath}."
        }

        $LineSep
        "Using code-signing certificate: $certificate"
        $LineSep

        $files = @(Get-ChildItem -Path $ModuleOutDir\* -Recurse -Include *.ps1,*.psm1)
        foreach ($file in $files) {
            $setAuthSigParams = @{
                FilePath = $file.FullName
                Certificate = $certificate
                Verbose = $VerbosePreference
            }

            $result = Microsoft.PowerShell.Security\Set-AuthenticodeSignature @setAuthSigParams
            if ($result.Status -ne 'Valid') {
                throw "Failed to sign script: $($file.FullName)."
            }

            "Successfully signed script: $($file.Name)"
        }
    }
    else {
        $expiredCert = Get-ChildItem -Path $CertPath -CodeSigningCert -Recurse |
                           Where-Object { ($_.SubjectName.Name -cmatch [regex]::Escape($CertSubjectName)) -and
                                          ($_.NotAfter -lt (Get-Date)) }
                           Sort-Object NotAfter -Descending | Select-Object -First 1

        if ($expiredCert) {
            throw "The code-signing certificate `"$($expiredCert.SubjectName.Name)`" EXPIRED on $($expiredCert.NotAfter)."
        }

        throw 'No valid certificate subject name supplied or stored.'
    }
}

Task BuildHelp -depends Build, BeforeBuildHelp, GenerateMarkdown, GenerateHelpFiles, AfterBuildHelp {
}

Task GenerateMarkdown -requiredVariables DefaultLocale, DocsRootDir, ModuleName, ModuleOutDir {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $moduleInfo = Import-Module $ModuleOutDir\$ModuleName.psd1 -Global -Force -PassThru

    try {
        if ($moduleInfo.ExportedCommands.Count -eq 0) {
            "No commands have been exported. Skipping $($psake.context.currentTaskName) task."
            return
        }

        if (!(Test-Path -LiteralPath $DocsRootDir)) {
            New-Item $DocsRootDir -ItemType Directory > $null
        }

        if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $DocsRootDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
        New-MarkdownHelp -Module $ModuleName -Locale $DefaultLocale -OutputFolder $DocsRootDir\$DefaultLocale `
                         -WithModulePage -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
    finally {
        Remove-Module $ModuleName
    }
}

Task GenerateHelpFiles -requiredVariables DocsRootDir, ModuleName, ModuleOutDir, OutDir {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    if (!(Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse -ErrorAction SilentlyContinue)) {
        "No markdown help files to process. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory).Name

    # Generate the module's primary MAML help file.
    foreach ($locale in $helpLocales) {
        New-ExternalHelp -Path $DocsRootDir\$locale -OutputPath $ModuleOutDir\$locale -Force `
                         -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
}

Task BuildUpdatableHelp -depends BuildHelp, BeforeBuildUpdatableHelp, CoreBuildUpdatableHelp, AfterBuildUpdatableHelp {
}

Task CoreBuildUpdatableHelp -requiredVariables DocsRootDir, ModuleName, UpdatableHelpOutDir {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory).Name

    # Create updatable help output directory.
    if (!(Test-Path -LiteralPath $UpdatableHelpOutDir)) {
        New-Item $UpdatableHelpOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "$($psake.context.currentTaskName) - directory already exists '$UpdatableHelpOutDir'."
        Get-ChildItem $UpdatableHelpOutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        New-ExternalHelpCab -CabFilesFolder $ModuleOutDir\$locale -LandingPagePath $DocsRootDir\$locale\$ModuleName.md `
                            -OutputFolder $UpdatableHelpOutDir -Verbose:$VerbosePreference > $null
    }
}

Task GenerateFileCatalog -depends Build, BuildHelp, BeforeGenerateFileCatalog, CoreGenerateFileCatalog, AfterGenerateFileCatalog {
}

Task CoreGenerateFileCatalog -requiredVariables CatalogGenerationEnabled, CatalogVersion, ModuleName, ModuleOutDir, OutDir {
    if (!$CatalogGenerationEnabled) {
        "FileCatalog generation is not enabled. Skipping $($psake.context.currentTaskName) task."
        return
    }

    if (!(Get-Command Microsoft.PowerShell.Security\New-FileCatalog -ErrorAction SilentlyContinue)) {
        "FileCatalog commands not available on this version of PowerShell. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $catalogFilePath = "$OutDir\$ModuleName.cat"

    $newFileCatalogParams = @{
        Path = $ModuleOutDir
        CatalogFilePath = $catalogFilePath
        CatalogVersion = $CatalogVersion
        Verbose = $VerbosePreference
    }

    Microsoft.PowerShell.Security\New-FileCatalog @newFileCatalogParams > $null

    if ($ScriptSigningEnabled) {
        if ($SharedProperties.CodeSigningCertificate) {
            $setAuthSigParams = @{
                FilePath = $catalogFilePath
                Certificate = $SharedProperties.CodeSigningCertificate
                Verbose = $VerbosePreference
            }

            $result = Microsoft.PowerShell.Security\Set-AuthenticodeSignature @setAuthSigParams
            if ($result.Status -ne 'Valid') {
                throw "Failed to sign file catalog: $($catalogFilePath)."
            }

            "Successfully signed file catalog: $($catalogFilePath)"
        }
        else {
            "No code-signing certificate was found to sign the file catalog."
        }
    }
    else {
        "Script signing is not enabled. Skipping signing of file catalog."
    }

    Move-Item -LiteralPath $newFileCatalogParams.CatalogFilePath -Destination $ModuleOutDir
}

Task Install -depends Build, BuildHelp, GenerateFileCatalog, BeforeInstall, CoreInstall, AfterInstall {
}

Task CoreInstall -requiredVariables ModuleOutDir {
    if (!(Test-Path -LiteralPath $InstallPath)) {
        Write-Verbose 'Creating install directory'
        New-Item -Path $InstallPath -ItemType Directory -Verbose:$VerbosePreference > $null
    }

    Copy-Item -Path $ModuleOutDir\* -Destination $InstallPath -Verbose:$VerbosePreference -Recurse -Force
    "Module installed into $InstallPath"
}

Task Test -depends Build -requiredVariables TestRootDir, ModuleName, CodeCoverageEnabled, CodeCoverageFiles {
    if (!(Get-Module Pester -ListAvailable)) {
        "Pester module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    Import-Module Pester

    try {
        Microsoft.PowerShell.Management\Push-Location -LiteralPath $TestRootDir

        if ($TestOutputFile) {
            $testing = @{
                OutputFile   = $TestOutputFile
                OutputFormat = $TestOutputFormat
                PassThru     = $true
                Verbose      = $VerbosePreference
            }
        }
        else {
            $testing = @{
                PassThru     = $true
                Verbose      = $VerbosePreference
            }
        }

        # To control the Pester code coverage, a boolean $CodeCoverageEnabled is used.
        if ($CodeCoverageEnabled) {
            $testing.CodeCoverage = $CodeCoverageFiles
        }

        $testResult = Invoke-Pester @testing

        Assert -conditionToCheck (
            $testResult.FailedCount -eq 0
        ) -failureMessage "One or more Pester tests failed, build cannot continue."

        if ($CodeCoverageEnabled) {
            $testCoverage = [int]($testResult.CodeCoverage.NumberOfCommandsExecuted /
                                  $testResult.CodeCoverage.NumberOfCommandsAnalyzed * 100)
            "Pester code coverage on specified files: ${testCoverage}%"
        }
    }
    finally {
        Microsoft.PowerShell.Management\Pop-Location
        Remove-Module $ModuleName -ErrorAction SilentlyContinue
    }
}

Task Publish -depends Build, Test, BuildHelp, GenerateFileCatalog, BeforePublish, CorePublish, AfterPublish {
}

Task CorePublish -requiredVariables SettingsPath, ModuleOutDir {
    $publishParams = @{
        Path        = $ModuleOutDir
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
        Path        = $ModuleOutDir
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
    $psake.context.Peek().Tasks.Keys | Sort-Object
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
