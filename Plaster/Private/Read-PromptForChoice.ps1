function Read-PromptForChoice {
    [CmdletBinding()]
    param(
        [string]
        $ParameterName,
        [ValidateNotNull()]
        $ChoiceNodes,
        [string]
        $prompt,
        [int[]]
        $defaults,
        [switch]
        $IsMultiChoice
    )
    $choices = New-Object 'System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]'
    $values = New-Object object[] $ChoiceNodes.Count
    $i = 0

    foreach ($choiceNode in $ChoiceNodes) {
        $label = Resolve-AttributeValue $choiceNode.label (Get-ErrorLocationParameterAttrVal $ParameterName label)
        $help = Resolve-AttributeValue $choiceNode.help  (Get-ErrorLocationParameterAttrVal $ParameterName help)
        $value = Resolve-AttributeValue $choiceNode.value (Get-ErrorLocationParameterAttrVal $ParameterName value)

        $choice = New-Object System.Management.Automation.Host.ChoiceDescription -Arg $label, $help
        $choices.Add($choice)
        $values[$i++] = $value
    }

    $returnValue = [PSCustomObject]@{Values = @(); Indices = @() }

    if ($IsMultiChoice) {
        $selections = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults)
        foreach ($selection in $selections) {
            $returnValue.Values += $values[$selection]
            $returnValue.Indices += $selection
        }
    } else {
        if ($defaults.Count -gt 1) {
            throw ($LocalizedData.ParameterTypeChoiceMultipleDefault_F1 -f $ChoiceNodes.ParentNode.name)
        }

        $selection = $Host.UI.PromptForChoice('', $prompt, $choices, $defaults[0])
        $returnValue.Values = $values[$selection]
        $returnValue.Indices = $selection
    }

    $returnValue
}
