# ISSUES:
# 1. Would be better perhaps if we had a schema to validate against rather than the manual
#    incorporated below.
# 2. Should this command use only Write-Error ($? is $true) or throw ($? is $false)?
# 3. Should this command output the manifest (XML) like Test-ModuleManifest outputs PSModuleInfo?

<#
.SYNOPSIS
    Verifies that a plaster manifest file is a valid.
.DESCRIPTION
    Verifies that a plaster manifest file is a valid.
.EXAMPLE
    C:\PS> Test-PlasterManifest plasterManifest.xml
    Verifies that the plasterManifest.xml file in the current directory
    is valid.
.INPUTS
    System.String
    You can pipe the path to a plaster manifest to Test-PlasterManifest.
.OUTPUTS
    System.Boolean
    Returns "True" when the plaster manifest file is valid and "False" when
    it isn't valid.
.NOTES
    General notes
#>
function Test-PlasterManifest {
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="Path",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is
        # used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
        # enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
        # characters as escape sequences.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="LiteralPath",
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath
    )

    process {
        $paths = @()
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }

                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }

                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }

        # Process each path
        foreach ($aPath in $paths) {
            $filename = Split-Path $aPath -Leaf
            $valid = $true

            if ($filename -ne 'plasterManifest.xml') {
                Write-Error ($LocalizedData.ManifestWrongFilename_F1 -f $aPath)
                $valid = $false
            }

            try {
                $manifest = [xml](Get-Content $aPath)
            }
            catch {
                Write-Error ($LocalizedData.ManifestNotValidXml_F1 -f $aPath)
                $false
                continue
            }

            # Validate the required elements of the manifest are present
            if (!$manifest.plasterManifest) {
                Write-Error ($LocalizedData.ManifestMissingElement_F1 -f 'plasterManifest (doc)')
                $false
                continue
            }
            if (!$manifest.plasterManifest.metadata) {
                Write-Error ($LocalizedData.ManifestMissingElement_F1 -f 'metadata')
                $false
                continue
            }
            if (!$manifest.plasterManifest.metadata.id) {
                Write-Error ($LocalizedData.ManifestMissingElement_F1 -f 'metadata id')
                $valid = $false
            }
            if (!$manifest.plasterManifest.metadata.version) {
                Write-Error ($LocalizedData.ManifestMissingElement_F1 -f 'metadata version')
                $valid = $false
            }
            if (!$manifest.plasterManifest.content) {
                Write-Error ($LocalizedData.ManifestMissingElement_F1 -f 'content')
                $valid = $false
            }

            $valid
        }
    }
}