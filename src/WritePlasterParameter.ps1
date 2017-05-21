<#
.SYNOPSIS
A simple helper function to create a parameter xml block for plaster
.DESCRIPTION
A simple helper function to create a parameter xml block for plaster.  This function
is best used with an array of hashtables for rapid creation of a Plaster parameter
block.
.PARAMETER Name
The plaster element name
.PARAMETER Type
The type of plater parameter. Can be either text, choice, multichoice, user-fullname, or user-email
.PARAMETER Prompt
The prompt to be displayed
.PARAMETER Default
The default setting for this parameter
.PARAMETER Store
Specifies the store type of the value. Can be text or encrypted. If not defined then the default is text.
.PARAMETER Choices
An array of hashtables with each hash being a choice containing the lable, help, and value for the choice.
.PARAMETER Obj
Hashtable object containing all the parameters required for this function.
.EXAMPLE
$choice1 = @{
    label = '&yes'
    help = 'Process this'
    value = 'true'
}
$choice2 = @{
    label = '&no'
    help = 'Do NOT Process this'
    value = 'false'
}

Write-PlasterParameter -Name 'Editor' -type 'choice' -Prompt 'Choose your editor' -Default '0' -Store 'text' -Choices @($choice1,$choice2)
.EXAMPLE
$MyParams = @(
@{
    'Name' = "NugetAPIKey"
    'Type' = "text"
    'Prompt' = "Enter a PowerShell Gallery (aka Nuget) API key. Without this you will not be able to upload your module to the Gallery"
    'Default' = ' '
},
@{
    'Name' = "OptionAnalyzeCode"
    'Type' = "choice"
    'Prompt' = "Use PSScriptAnalyzer in the module build process (Recommended for Gallery uploading)?"
    'Default' = "0"
    'Store' = "text"
    'Choices' = @(
        @{
            Label = "&Yes"
            Help = "Enable script analysis"
            Value = "True"
        },
        @{
            Label = "&No"
            Help = "Disable script analysis"
            Value = "False"
        }
    )
}) | Write-PlasterParameter
#>
function Write-PlasterParameter {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 0)]
        [Alias('Name')]
        [string]$ParameterName,

        [Parameter(ParameterSetName = "default", Position = 1)]
        [ValidateSet('text', 'choice', 'multichoice', 'user-fullname', 'user-email')]
        [Alias('Type')]
        [string]$ParameterType = 'text',

        [Parameter(ParameterSetName = "default", Mandatory = $true, Position = 2)]
        [Alias('Prompt')]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterPrompt,

        [Parameter(ParameterSetName = "default", Position = 3)]
        [Alias('Default')]
        [string]$ParameterDefault,

        [Parameter(ParameterSetName = "default", Position = 4)]
        [ValidateSet('text', 'encrypted')]
        [AllowNull()]
        [string]$Store,

        [Parameter(ParameterSetName = "default", Position = 5)]
        [Hashtable[]]$Choices,

        [Parameter(ParameterSetName = "pipeline", ValueFromPipeLine = $true, Position = 0)]
        [Hashtable]$Obj
    )

    process {
        # If a hash is passed then recall this function with the hash splatted instead.
        if ($null -ne $Obj) {
            return Write-PlasterParameter @Obj
        }

        # Create a new XML File with config root node
        $oXMLRoot = New-Object System.XML.XMLDocument

        if (($Type -eq 'choice') -and ($Choices.Count -le 1)) {
            throw 'You cannot setup a parameter of type "choice" without supplying an array of applicable choices to select from...'
        }

        # New Node
        $oXMLParameter = $oXMLRoot.CreateElement("parameter")

        # Append as child to an existing node
        $Null = $oXMLRoot.appendChild($oXMLParameter)

        # Add a Attributes
        $oXMLParameter.SetAttribute("name", $ParameterName)
        $oXMLParameter.SetAttribute("type", $ParameterType)
        $oXMLParameter.SetAttribute("prompt", $ParameterPrompt)
        if (-not [string]::IsNullOrEmpty($ParameterDefault)) {
            $oXMLParameter.SetAttribute("default", $ParameterDefault)
        }
        if (-not [string]::IsNullOrEmpty($Store)) {
            $oXMLParameter.SetAttribute("store", $Store)
        }
        if ($ParameterType -match 'choice|multichoice') {
            if ($Choices.count -lt 1) {
                Write-Warning 'The parameter type was choice/multichoice but there are less than 2 choices. Returning nothing.'
                return
            }
            foreach ($Choice in $Choices) {
                [System.XML.XMLElement]$oXMLChoice = $oXMLRoot.CreateElement("choice")
                $oXMLChoice.SetAttribute("label", $Choice['Label'])
                $oXMLChoice.SetAttribute("help", $Choice['help'])
                $oXMLChoice.SetAttribute("value", $Choice['value'])
                $null = $oXMLRoot['parameter'].appendChild($oXMLChoice)
            }
        }

        $oXMLRoot.InnerXML
    }
}
