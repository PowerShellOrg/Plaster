#Requires -Version 5.1
#Requires -Modules InvokeBuild

<#
.SYNOPSIS
    Modern build script for Plaster 2.0 using InvokeBuild

.DESCRIPTION
    This build script replaces the legacy psake build system with a modern,
    cross-platform build process using InvokeBuild. Supports PowerShell 5.1+
    and PowerShell 7.x on Windows, Linux, and macOS.

.PARAMETER Task
    The build task(s) to execute. Default is 'Build'.

.PARAMETER Configuration
    The build configuration (Debug/Release). Default is 'Release'.

.PARAMETER OutputPath
    The output directory for build artifacts. Default is './Output'.

.PARAMETER ModuleName
    The name of the module being built. Default is 'Plaster'.

.PARAMETER SkipTests
    Skip running tests during the build process.

.PARAMETER SkipAnalysis
    Skip running PSScriptAnalyzer during the build process.

.PARAMETER PublishToGallery
    Publish the module to PowerShell Gallery after successful build and test.

.PARAMETER NuGetApiKey
    API key for publishing to PowerShell Gallery.

.EXAMPLE
    ./build.ps1
    Runs the default Build task

.EXAMPLE
    ./build.ps1 -Task Test
    Runs only the Test task

.EXAMPLE
    ./build.ps1 -Task Build, Test, Publish -PublishToGallery -NuGetApiKey $apiKey
    Builds, tests, and publishes the module
#>

[CmdletBinding()]
param(
  [Parameter()]
  [ValidateSet('Clean', 'Build', 'Test', 'Analyze', 'Package', 'Publish', 'Install')]
  [string[]]$Task = @('Build'),

  [Parameter()]
  [ValidateSet('Debug', 'Release')]
  [string]$Configuration = 'Release',

  [Parameter()]
  [string]$OutputPath = './Output',

  [Parameter()]
  [string]$ModuleName = 'Plaster',

  [Parameter()]
  [switch]$SkipTests,

  [Parameter()]
  [switch]$SkipAnalysis,

  [Parameter()]
  [switch]$PublishToGallery,

  [Parameter()]
  [string]$NuGetApiKey
)

# Build configuration
$script:BuildConfig = @{
  ModuleName     = $ModuleName
  SourcePath     = './src'
  OutputPath     = $OutputPath
  TestPath       = './tests'
  DocsPath       = './docs'
  Configuration  = $Configuration
  ModuleVersion  = $null  # Will be read from manifest
  BuildNumber    = $env:BUILD_NUMBER ?? '0'
  IsCI           = $null -ne $env:CI

  # Tool paths
  Tools          = @{
    Pester           = $null
    PSScriptAnalyzer = $null
    platyPS          = $null
  }

  # Test configuration
  TestConfig     = @{
    OutputFormat = 'NUnitXml'
    OutputPath   = Join-Path $OutputPath 'TestResults.xml'
    CodeCoverage = @{
      Enabled      = $true
      OutputPath   = Join-Path $OutputPath 'CodeCoverage.xml'
      OutputFormat = 'JaCoCo'
      Threshold    = 80
    }
  }

  # Analysis configuration
  AnalysisConfig = @{
    Enabled      = -not $SkipAnalysis
    SettingsPath = './PSScriptAnalyzerSettings.psd1'
    Severity     = @('Error', 'Warning', 'Information')
    ExcludeRules = @()
  }

  # Publish configuration
  PublishConfig  = @{
    Repository = 'PSGallery'
    ApiKey     = $NuGetApiKey
    Tags       = @('Plaster', 'CodeGenerator', 'Scaffold', 'Template', 'PowerShell7')
  }
}

# Bootstrap required modules
task Bootstrap {
  Write-Host "Bootstrapping build dependencies..." -ForegroundColor Cyan

  $requiredModules = @(
    @{ Name = 'Pester'; MinimumVersion = '5.0.0' }
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.19.0' }
    @{ Name = 'platyPS'; MinimumVersion = '0.14.0' }
    @{ Name = 'PowerShellGet'; MinimumVersion = '2.2.0' }
  )

  foreach ($module in $requiredModules) {
    $installed = Get-Module -Name $module.Name -ListAvailable |
    Where-Object { $_.Version -ge $module.MinimumVersion } |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $installed) {
      Write-Host "Installing $($module.Name) >= $($module.MinimumVersion)..." -ForegroundColor Yellow
      Install-Module -Name $module.Name -MinimumVersion $module.MinimumVersion -Scope CurrentUser -Force -AllowClobber
    } else {
      Write-Host "$($module.Name) $($installed.Version) is already installed" -ForegroundColor Green
    }

    # Cache tool paths
    $script:BuildConfig.Tools[$module.Name] = Get-Module -Name $module.Name -ListAvailable |
    Sort-Object Version -Descending |
    Select-Object -First 1
  }
}

# Clean build artifacts
task Clean {
  Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan

  if (Test-Path $script:BuildConfig.OutputPath) {
    Remove-Item -Path $script:BuildConfig.OutputPath -Recurse -Force
    Write-Host "Removed output directory: $($script:BuildConfig.OutputPath)" -ForegroundColor Green
  }

  # Clean any temp files
  Get-ChildItem -Path . -Filter "*.tmp" -Recurse | Remove-Item -Force
  Get-ChildItem -Path . -Filter "TestResults*.xml" -Recurse | Remove-Item -Force
}

# Initialize build environment
task Init Clean, {
  Write-Host "Initializing build environment..." -ForegroundColor Cyan

  # Create output directory
  if (-not (Test-Path $script:BuildConfig.OutputPath)) {
    New-Item -Path $script:BuildConfig.OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Created output directory: $($script:BuildConfig.OutputPath)" -ForegroundColor Green
  }

  # Read module version from manifest
  $manifestPath = Join-Path $script:BuildConfig.SourcePath "$($script:BuildConfig.ModuleName).psd1"
  if (Test-Path $manifestPath) {
    $manifest = Test-ModuleManifest -Path $manifestPath
    $script:BuildConfig.ModuleVersion = $manifest.Version
    Write-Host "Module version: $($script:BuildConfig.ModuleVersion)" -ForegroundColor Green
  } else {
    throw "Module manifest not found at: $manifestPath"
  }
}

# Build the module
task Build Init, {
  Write-Host "Building module..." -ForegroundColor Cyan

  $moduleOutputPath = Join-Path $script:BuildConfig.OutputPath $script:BuildConfig.ModuleName

  # Create module directory
  if (-not (Test-Path $moduleOutputPath)) {
    New-Item -Path $moduleOutputPath -ItemType Directory -Force | Out-Null
  }

  # Copy source files
  $sourceFiles = @(
    '*.psd1', '*.psm1', '*.ps1', '*.dll'
    'Templates', 'Schema', 'en-US'
  )

  foreach ($pattern in $sourceFiles) {
    $items = Get-ChildItem -Path $script:BuildConfig.SourcePath -Filter $pattern -ErrorAction SilentlyContinue
    if ($items) {
      foreach ($item in $items) {
        $destination = Join-Path $moduleOutputPath $item.Name
        if ($item.PSIsContainer) {
          Copy-Item -Path $item.FullName -Destination $destination -Recurse -Force
        } else {
          Copy-Item -Path $item.FullName -Destination $destination -Force
        }
        Write-Verbose "Copied: $($item.Name)"
      }
    }
  }

  # Update module manifest with build metadata
  $manifestPath = Join-Path $moduleOutputPath "$($script:BuildConfig.ModuleName).psd1"
  if (Test-Path $manifestPath) {
    $content = Get-Content -Path $manifestPath -Raw

    # Add build metadata to private data
    $buildInfo = @{
      BuildDate   = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
      BuildNumber = $script:BuildConfig.BuildNumber
      PSVersion   = $PSVersionTable.PSVersion
      Platform    = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    }

    $buildInfoJson = $buildInfo | ConvertTo-Json -Compress
    $content = $content -replace '(# Build metadata placeholder)', "BuildInfo = '$buildInfoJson'"

    Set-Content -Path $manifestPath -Value $content -Encoding UTF8
    Write-Host "Updated manifest with build metadata" -ForegroundColor Green
  }

  Write-Host "Module built successfully at: $moduleOutputPath" -ForegroundColor Green
}

# Run PSScriptAnalyzer
task Analyze {
  if (-not $script:BuildConfig.AnalysisConfig.Enabled) {
    Write-Host "Analysis skipped (disabled)" -ForegroundColor Yellow
    return
  }

  Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan

  Import-Module PSScriptAnalyzer -Force

  $analyzeParams = @{
    Path     = $script:BuildConfig.SourcePath
    Recurse  = $true
    Settings = $script:BuildConfig.AnalysisConfig.SettingsPath
    Severity = $script:BuildConfig.AnalysisConfig.Severity
  }

  if ($script:BuildConfig.AnalysisConfig.ExcludeRules) {
    $analyzeParams.ExcludeRule = $script:BuildConfig.AnalysisConfig.ExcludeRules
  }

  $results = Invoke-ScriptAnalyzer @analyzeParams

  if ($results) {
    $results | Format-Table -AutoSize

    $errors = $results | Where-Object Severity -eq 'Error'
    $warnings = $results | Where-Object Severity -eq 'Warning'

    Write-Host "Analysis completed: $($errors.Count) errors, $($warnings.Count) warnings" -ForegroundColor Yellow

    if ($errors) {
      throw "PSScriptAnalyzer found $($errors.Count) error(s). Build cannot continue."
    }
  } else {
    Write-Host "PSScriptAnalyzer found no issues" -ForegroundColor Green
  }
}

# Run Pester tests
task Test Build, {
  if ($SkipTests) {
    Write-Host "Tests skipped" -ForegroundColor Yellow
    return
  }

  Write-Host "Running Pester tests..." -ForegroundColor Cyan

  Import-Module Pester -Force -MinimumVersion 5.0

  # Configure Pester
  $pesterConfig = New-PesterConfiguration

  # Run settings
  $pesterConfig.Run.Path = $script:BuildConfig.TestPath
  $pesterConfig.Run.PassThru = $true

  # Output settings
  $pesterConfig.Output.Verbosity = 'Detailed'

  # Test result settings
  $pesterConfig.TestResult.Enabled = $true
  $pesterConfig.TestResult.OutputFormat = $script:BuildConfig.TestConfig.OutputFormat
  $pesterConfig.TestResult.OutputPath = $script:BuildConfig.TestConfig.OutputPath

  # Code coverage settings
  if ($script:BuildConfig.TestConfig.CodeCoverage.Enabled) {
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.OutputFormat = $script:BuildConfig.TestConfig.CodeCoverage.OutputFormat
    $pesterConfig.CodeCoverage.OutputPath = $script:BuildConfig.TestConfig.CodeCoverage.OutputPath

    # Include source files for coverage
    $sourceFiles = Get-ChildItem -Path $script:BuildConfig.SourcePath -Filter "*.ps1" -Recurse |
    Where-Object { $_.Name -notmatch '\.Tests\.ps1' } |
    ForEach-Object { $_.FullName }

    if ($sourceFiles) {
      $pesterConfig.CodeCoverage.Path = $sourceFiles
    }
  }

  # Run tests
  $testResults = Invoke-Pester -Configuration $pesterConfig

  # Check results
  if ($testResults.FailedCount -gt 0) {
    throw "Pester tests failed: $($testResults.FailedCount) failed, $($testResults.PassedCount) passed"
  }

  # Check code coverage
  if ($script:BuildConfig.TestConfig.CodeCoverage.Enabled -and $testResults.CodeCoverage) {
    $coveragePercent = [math]::Round($testResults.CodeCoverage.CoveragePercent, 2)
    $threshold = $script:BuildConfig.TestConfig.CodeCoverage.Threshold

    Write-Host "Code coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge $threshold) { 'Green' } else { 'Red' })

    if ($coveragePercent -lt $threshold) {
      Write-Warning "Code coverage ($coveragePercent%) is below threshold ($threshold%)"
    }
  }

  Write-Host "All tests passed: $($testResults.PassedCount) passed, $($testResults.FailedCount) failed" -ForegroundColor Green
}

# Generate documentation
task Docs Build, {
  Write-Host "Generating documentation..." -ForegroundColor Cyan

  try {
    Import-Module platyPS -Force

    $moduleOutputPath = Join-Path $script:BuildConfig.OutputPath $script:BuildConfig.ModuleName
    $docsOutputPath = Join-Path $script:BuildConfig.OutputPath 'docs'

    # Import the built module
    Import-Module $moduleOutputPath -Force

    # Create docs directory
    if (-not (Test-Path $docsOutputPath)) {
      New-Item -Path $docsOutputPath -ItemType Directory -Force | Out-Null
    }

    # Generate markdown help
    New-MarkdownHelp -Module $script:BuildConfig.ModuleName -OutputFolder $docsOutputPath -Force

    # Generate external help
    $helpOutputPath = Join-Path $moduleOutputPath 'en-US'
    if (-not (Test-Path $helpOutputPath)) {
      New-Item -Path $helpOutputPath -ItemType Directory -Force | Out-Null
    }

    New-ExternalHelp -Path $docsOutputPath -OutputPath $helpOutputPath -Force

    Write-Host "Documentation generated successfully" -ForegroundColor Green
  } catch {
    Write-Warning "Documentation generation failed: $($_.Exception.Message)"
  } finally {
    Remove-Module $script:BuildConfig.ModuleName -ErrorAction SilentlyContinue
  }
}

# Package the module
task Package Build, Test, Analyze, Docs, {
  Write-Host "Packaging module..." -ForegroundColor Cyan

  $moduleOutputPath = Join-Path $script:BuildConfig.OutputPath $script:BuildConfig.ModuleName
  $packagePath = Join-Path $script:BuildConfig.OutputPath "$($script:BuildConfig.ModuleName).$($script:BuildConfig.ModuleVersion).nupkg"

  # Create a staging directory for packaging
  $stagingPath = Join-Path $script:BuildConfig.OutputPath 'staging'
  if (Test-Path $stagingPath) {
    Remove-Item -Path $stagingPath -Recurse -Force
  }

  # Copy module to staging
  Copy-Item -Path $moduleOutputPath -Destination $stagingPath -Recurse -Force

  # Create package manifest
  $packageManifest = @{
    ModuleName    = $script:BuildConfig.ModuleName
    ModuleVersion = $script:BuildConfig.ModuleVersion
    BuildDate     = Get-Date
    Configuration = $script:BuildConfig.Configuration
    Platform      = $PSVersionTable.Platform ?? 'Windows'
  }

  $packageManifest | ConvertTo-Json | Out-File -FilePath (Join-Path $stagingPath 'package.json') -Encoding UTF8

  Write-Host "Module packaged at: $stagingPath" -ForegroundColor Green
}

# Install the module locally
task Install Package, {
  Write-Host "Installing module locally..." -ForegroundColor Cyan

  $moduleOutputPath = Join-Path $script:BuildConfig.OutputPath $script:BuildConfig.ModuleName

  # Determine installation path
  $installPath = if ($IsWindows) {
    Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$($script:BuildConfig.ModuleName)"
  } else {
    Join-Path $HOME ".local/share/powershell/Modules/$($script:BuildConfig.ModuleName)"
  }

  # Remove existing installation
  if (Test-Path $installPath) {
    Remove-Item -Path $installPath -Recurse -Force
    Write-Host "Removed existing installation: $installPath" -ForegroundColor Yellow
  }

  # Create installation directory
  $versionPath = Join-Path $installPath $script:BuildConfig.ModuleVersion
  New-Item -Path $versionPath -ItemType Directory -Force | Out-Null

  # Copy module files
  Copy-Item -Path "$moduleOutputPath\*" -Destination $versionPath -Recurse -Force

  Write-Host "Module installed at: $versionPath" -ForegroundColor Green

  # Test installation
  try {
    Import-Module $script:BuildConfig.ModuleName -Force
    $importedModule = Get-Module $script:BuildConfig.ModuleName
    Write-Host "Installation verified: $($importedModule.Name) v$($importedModule.Version)" -ForegroundColor Green
  } catch {
    throw "Installation verification failed: $($_.Exception.Message)"
  } finally {
    Remove-Module $script:BuildConfig.ModuleName -ErrorAction SilentlyContinue
  }
}

# Publish to PowerShell Gallery
task Publish Package, {
  if (-not $PublishToGallery) {
    Write-Host "Publish skipped (not requested)" -ForegroundColor Yellow
    return
  }

  if (-not $script:BuildConfig.PublishConfig.ApiKey) {
    throw "NuGetApiKey is required for publishing to PowerShell Gallery"
  }

  Write-Host "Publishing to PowerShell Gallery..." -ForegroundColor Cyan

  $moduleOutputPath = Join-Path $script:BuildConfig.OutputPath $script:BuildConfig.ModuleName

  $publishParams = @{
    Path        = $moduleOutputPath
    Repository  = $script:BuildConfig.PublishConfig.Repository
    NuGetApiKey = $script:BuildConfig.PublishConfig.ApiKey
    Force       = $true
    Verbose     = $true
  }

  try {
    Publish-Module @publishParams
    Write-Host "Module published successfully to $($script:BuildConfig.PublishConfig.Repository)" -ForegroundColor Green
  } catch {
    throw "Publishing failed: $($_.Exception.Message)"
  }
}

# Default task
task . Bootstrap, Build

# CI/CD task
task CI Bootstrap, Clean, Build, Analyze, Test, Package

# Full pipeline task
task Pipeline Bootstrap, Clean, Build, Analyze, Test, Docs, Package, Install

# Release task
task Release Bootstrap, Clean, Build, Analyze, Test, Docs, Package, Publish

# Show build configuration
task ShowConfig {
  Write-Host "Build Configuration:" -ForegroundColor Cyan
  Write-Host "  Module Name: $($script:BuildConfig.ModuleName)" -ForegroundColor White
  Write-Host "  Module Version: $($script:BuildConfig.ModuleVersion)" -ForegroundColor White
  Write-Host "  Configuration: $($script:BuildConfig.Configuration)" -ForegroundColor White
  Write-Host "  Output Path: $($script:BuildConfig.OutputPath)" -ForegroundColor White
  Write-Host "  Source Path: $($script:BuildConfig.SourcePath)" -ForegroundColor White
  Write-Host "  Test Path: $($script:BuildConfig.TestPath)" -ForegroundColor White
  Write-Host "  Platform: $($PSVersionTable.Platform ?? 'Windows')" -ForegroundColor White
  Write-Host "  PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
  Write-Host "  Is CI: $($script:BuildConfig.IsCI)" -ForegroundColor White
}