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
                   ParameterSetName='Path',
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
                   ParameterSetName='LiteralPath',
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Literal path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath,

        [Parameter(Mandatory=$true,
                   ParameterSetName='InputObject',
                   ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [System.Xml.XmlDocument]
        $InputObject
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
                $objs += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        elseif ($psCmdlet.ParameterSetName -eq 'LiteralPath') {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }

                # Resolve any relative paths
                $objs += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
        else {
            $objs = $InputObject
        }

        # Process each path
        foreach ($obj in $objs) {
            if ($psCmdlet.ParameterSetName -eq 'InputObject') {
                $manifest = $obj
            }
            else {
                $filename = Split-Path $obj -Leaf
                $valid = $true

                if ($filename -ne 'plasterManifest.xml') {
                    Write-Error ($LocalizedData.ManifestWrongFilename_F1 -f $obj)
                    $valid = $false
                }

                try {
                    $manifest = [xml](Get-Content $obj)
                }
                catch {
                    Write-Error ($LocalizedData.ManifestNotValidXml_F1 -f $obj)
                    $false
                    continue
                }
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