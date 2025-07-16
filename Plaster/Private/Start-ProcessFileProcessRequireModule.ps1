function Start-ProcessFileProcessRequireModule {
    [CmdletBinding()]
    param(
        [ValidateNotNull()]
        $Node
    )

    $name = $Node.name

    $condition = $Node.condition
    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        $PSCmdlet.WriteDebug("Skipping $($Node.localName) for module '$name', condition evaluated to false.")
        return
    }

    $message = Resolve-AttributeValue $Node.message (Get-ErrorLocationRequireModuleAttrVal $name message)
    $minimumVersion = $Node.minimumVersion
    $maximumVersion = $Node.maximumVersion
    $requiredVersion = $Node.requiredVersion

    $getModuleParams = @{
        ListAvailable = $true
        ErrorAction = 'SilentlyContinue'
    }

    # Configure $getModuleParams with correct parameters based on parameterset to be used.
    # Also construct an array of version strings that can be displayed to the user.
    $versionInfo = @()
    if ($requiredVersion) {
        $getModuleParams["FullyQualifiedName"] = @{ModuleName = $name; RequiredVersion = $requiredVersion }
        $versionInfo += $LocalizedData.RequireModuleRequiredVersion_F1 -f $requiredVersion
    } elseif ($minimumVersion -or $maximumVersion) {
        $getModuleParams["FullyQualifiedName"] = @{ModuleName = $name }

        if ($minimumVersion) {
            $getModuleParams.FullyQualifiedName["ModuleVersion"] = $minimumVersion
            $versionInfo += $LocalizedData.RequireModuleMinVersion_F1 -f $minimumVersion
        }
        if ($maximumVersion) {
            $getModuleParams.FullyQualifiedName["MaximumVersion"] = $maximumVersion
            $versionInfo += $LocalizedData.RequireModuleMaxVersion_F1 -f $maximumVersion
        }
    } else {
        $getModuleParams["Name"] = $name
    }

    # Flatten array of version strings into a single string.
    $versionRequirements = ""
    if ($versionInfo.Length -gt 0) {
        $OFS = ", "
        $versionRequirements = " ($versionInfo)"
    }

    # PowerShell v3 Get-Module command does not have the FullyQualifiedName parameter.
    if ($PSVersionTable.PSVersion.Major -lt 4) {
        $getModuleParams.Remove("FullyQualifiedName")
        $getModuleParams["Name"] = $name
    }

    $module = Get-Module @getModuleParams

    $moduleDesc = if ($versionRequirements) { "${name}:$versionRequirements" } else { $name }

    if ($null -eq $module) {
        Write-OperationStatus $LocalizedData.OpMissing ($LocalizedData.RequireModuleMissing_F2 -f $name, $versionRequirements)
        if ($message) {
            Write-OperationAdditionalStatus $message
        }
        if ($PassThru) {
            $InvokePlasterInfo.MissingModules += $moduleDesc
        }
    } else {
        if ($PSVersionTable.PSVersion.Major -gt 3) {
            Write-OperationStatus $LocalizedData.OpVerify ($LocalizedData.RequireModuleVerified_F2 -f $name, $versionRequirements)
        } else {
            # On V3, we have to the version matching with the results that Get-Module return.
            $installedVersion = $module | Sort-Object Version -Descending | Select-Object -First 1 | ForEach-Object Version
            if ($installedVersion.Build -eq -1) {
                $installedVersion = [System.Version]"${installedVersion}.0.0"
            } elseif ($installedVersion.Revision -eq -1) {
                $installedVersion = [System.Version]"${installedVersion}.0"
            }

            if (($requiredVersion -and ($installedVersion -ne $requiredVersion)) -or
                ($minimumVersion -and ($installedVersion -lt $minimumVersion)) -or
                ($maximumVersion -and ($installedVersion -gt $maximumVersion))) {

                Write-OperationStatus $LocalizedData.OpMissing ($LocalizedData.RequireModuleMissing_F2 -f $name, $versionRequirements)
                if ($PassThru) {
                    $InvokePlasterInfo.MissingModules += $moduleDesc
                }
            } else {
                Write-OperationStatus $LocalizedData.OpVerify ($LocalizedData.RequireModuleVerified_F2 -f $name, $versionRequirements)
            }
        }
    }
}
