properties {
  if ($galleryApiKey) {
    $PSBPreference.Publish.PSRepositoryApiKey = $galleryApiKey.GetNetworkCredential().password
  }
  $PSBPreference.Test.OutputFile = 'Out/testResults.xml'
  # Using JUnitXML since that can be picked up by github workflow
  $PSBPreference.Test.OutputFormat = 'JUnitXml'
}

task default -depends test

task Test -FromModule PowerShellBuild -Version 0.6.1

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
  } elseif (!$CertSubjectName) {
    "A code-signing certificate has not been specified."
    "The following non-expired, code-signing certificates are available in your certificate store:"
    $validCodeSigningCerts | Format-List Subject, Issuer, Thumbprint, NotBefore, NotAfter

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
    } else {
      "Using stored certificate subject name $CertSubjectName from ${SettingsPath}."
    }

    $LineSep
    "Using code-signing certificate: $certificate"
    $LineSep

    $files = @(Get-ChildItem -Path $ModuleOutDir\* -Recurse -Include *.ps1, *.psm1)
    foreach ($file in $files) {
      $setAuthSigParams = @{
        FilePath    = $file.FullName
        Certificate = $certificate
        Verbose     = $VerbosePreference
      }

      $result = Microsoft.PowerShell.Security\Set-AuthenticodeSignature @setAuthSigParams
      if ($result.Status -ne 'Valid') {
        throw "Failed to sign script: $($file.FullName)."
      }

      "Successfully signed script: $($file.Name)"
    }
  } else {
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

Task CoreGenerateFileCatalog -requiredVariables CatalogGenerationEnabled, CatalogVersion, ModuleName, ModuleOutDir, OutDir {
  if (!$CatalogGenerationEnabled) {
    "FileCatalog generation is not enabled. Skipping $($psake.context.currentTaskName) task."
    return
  }

  if (!(Get-Command Microsoft.PowerShell.Security\New-FileCatalog -ErrorAction SilentlyContinue)) {
    "FileCatalog commands not available on this version of PowerShell. Skipping $($psake.context.currentTaskName) task."
    return
  }

  $catalogFilePath = "$env:BHBuildOutput\$ModuleName.cat"

  $newFileCatalogParams = @{
    Path            = $ModuleOutDir
    CatalogFilePath = $catalogFilePath
    CatalogVersion  = $CatalogVersion
    Verbose         = $VerbosePreference
  }

  Microsoft.PowerShell.Security\New-FileCatalog @newFileCatalogParams > $null

  if ($ScriptSigningEnabled) {
    if ($SharedProperties.CodeSigningCertificate) {
      $setAuthSigParams = @{
        FilePath    = $catalogFilePath
        Certificate = $SharedProperties.CodeSigningCertificate
        Verbose     = $VerbosePreference
      }

      $result = Microsoft.PowerShell.Security\Set-AuthenticodeSignature @setAuthSigParams
      if ($result.Status -ne 'Valid') {
        throw "Failed to sign file catalog: $($catalogFilePath)."
      }

      "Successfully signed file catalog: $($catalogFilePath)"
    } else {
      "No code-signing certificate was found to sign the file catalog."
    }
  } else {
    "Script signing is not enabled. Skipping signing of file catalog."
  }

  Move-Item -LiteralPath $newFileCatalogParams.CatalogFilePath -Destination $ModuleOutDir
}
