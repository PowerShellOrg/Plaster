function Resolve-ProcessNewModuleManifest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateNotNull()]$Node
    )
    $moduleVersion = Resolve-AttributeValue $Node.moduleVersion (Get-ErrorLocationNewModManifestAttrVal moduleVersion)
    $rootModule = Resolve-AttributeValue $Node.rootModule (Get-ErrorLocationNewModManifestAttrVal rootModule)
    $author = Resolve-AttributeValue $Node.author (Get-ErrorLocationNewModManifestAttrVal author)
    $companyName = Resolve-AttributeValue $Node.companyName (Get-ErrorLocationNewModManifestAttrVal companyName)
    $description = Resolve-AttributeValue $Node.description (Get-ErrorLocationNewModManifestAttrVal description)
    $dstRelPath = Resolve-AttributeValue $Node.destination (Get-ErrorLocationNewModManifestAttrVal destination)
    $powerShellVersion = Resolve-AttributeValue $Node.powerShellVersion (Get-ErrorLocationNewModManifestAttrVal powerShellVersion)
    $nestedModules = Resolve-AttributeValue $Node.NestedModules (Get-ErrorLocationNewModManifestAttrVal NestedModules)
    $dscResourcesToExport = Resolve-AttributeValue $Node.DscResourcesToExport (Get-ErrorLocationNewModManifestAttrVal DscResourcesToExport)
    $copyright = Resolve-AttributeValue $Node.copyright (Get-ErrorLocationNewModManifestAttrVal copyright)

    # We could choose to not check this if the condition eval'd to false
    # but I think it is better to let the template author know they've broken the
    # rules for any of the file directives (not just the ones they're testing/enabled).
    if ([System.IO.Path]::IsPathRooted($dstRelPath)) {
        throw ($LocalizedData.ErrorPathMustBeRelativePath_F2 -f $dstRelPath, $Node.LocalName)
    }

    $dstPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath((Join-Path $DestinationPath $dstRelPath))

    $condition = $Node.condition
    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        $PSCmdlet.WriteDebug("Skipping module manifest generation for '$dstPath', condition evaluated to false.")
        return
    }

    $encoding = $Node.encoding
    if (!$encoding) {
        $encoding = $DefaultEncoding
    }

    if ($PSCmdlet.ShouldProcess($dstPath, $LocalizedData.ShouldProcessNewModuleManifest)) {
        $manifestDir = Split-Path $dstPath -Parent
        if (!(Test-Path $manifestDir)) {
            Test-PathIsUnderDestinationPath $manifestDir
            Write-Verbose ($LocalizedData.NewModManifest_CreatingDir_F1 -f $manifestDir)
            New-Item $manifestDir -ItemType Directory > $null
        }

        $newModuleManifestParams = @{}

        # If there is an existing module manifest, load it so we can reuse old values not specified by
        # template.
        if (Test-Path -LiteralPath $dstPath) {
            $manifestFileName = Split-Path $dstPath -Leaf
            $newModuleManifestParams = Import-LocalizedData -BaseDirectory $manifestDir -FileName $manifestFileName
            if ($newModuleManifestParams.PrivateData) {
                $newModuleManifestParams += $newModuleManifestParams.PrivateData.psdata
                $newModuleManifestParams.Remove('PrivateData')
            }
        }

        if (![string]::IsNullOrWhiteSpace($moduleVersion)) {
            $newModuleManifestParams['ModuleVersion'] = $moduleVersion
        }
        if (![string]::IsNullOrWhiteSpace($rootModule)) {
            $newModuleManifestParams['RootModule'] = $rootModule
        }
        if (![string]::IsNullOrWhiteSpace($author)) {
            $newModuleManifestParams['Author'] = $author
        }
        if (![string]::IsNullOrWhiteSpace($companyName)) {
            $newModuleManifestParams['CompanyName'] = $companyName
        }
        if (![string]::IsNullOrWhiteSpace($copyright)) {
            $newModuleManifestParams['Copyright'] = $copyright
        }
        if (![string]::IsNullOrWhiteSpace($description)) {
            $newModuleManifestParams['Description'] = $description
        }
        if (![string]::IsNullOrWhiteSpace($powerShellVersion)) {
            $newModuleManifestParams['PowerShellVersion'] = $powerShellVersion
        }
        if (![string]::IsNullOrWhiteSpace($nestedModules)) {
            $newModuleManifestParams['NestedModules'] = $nestedModules
        }
        if (![string]::IsNullOrWhiteSpace($dscResourcesToExport)) {
            $newModuleManifestParams['DscResourcesToExport'] = $dscResourcesToExport
        }

        $tempFile = $null

        try {
            $tempFileBaseName = "moduleManifest-" + [Guid]::NewGuid()
            $tempFile = [System.IO.Path]::GetTempPath() + "${tempFileBaseName}.psd1"
            $PSCmdlet.WriteDebug("Created temp file for new module manifest - $tempFile")
            $newModuleManifestParams['Path'] = $tempFile

            # Generate manifest into a temp file.
            New-ModuleManifest @newModuleManifestParams

            # Typically the manifest is re-written with a new encoding (UTF8-NoBOM) because Git hates UTF-16.
            $content = Get-Content -LiteralPath $tempFile -Raw

            # Replace the temp filename in the generated manifest file's comment header with the actual filename.
            $dstBaseName = [System.IO.Path]::GetFileNameWithoutExtension($dstPath)
            $content = $content -replace "(?<=\s*#.*?)$tempFileBaseName", $dstBaseName

            Write-ContentWithEncoding -Path $tempFile -Content $content -Encoding $encoding

            Copy-FileWithConflictDetection $tempFile $dstPath

            if ($PassThru -and ($Node.openInEditor -eq 'true')) {
                $InvokePlasterInfo.OpenFiles += $dstPath
            }
        } finally {
            if ($tempFile -and (Test-Path $tempFile)) {
                Remove-Item -LiteralPath $tempFile
                $PSCmdlet.WriteDebug("Removed temp file for new module manifest - $tempFile")
            }
        }
    }
}
