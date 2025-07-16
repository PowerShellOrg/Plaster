function Resolve-ProcessParameter {
    [CmdletBinding()]
    param(
        [ValidateNotNull()]$Node
    )

    $name = $Node.name
    $type = $Node.type
    $store = $Node.store

    $pattern = $Node.pattern

    $condition = $Node.condition

    $default = Resolve-AttributeValue $Node.default (Get-ErrorLocationParameterAttrVal $name default)

    if ($condition -and !(Test-ConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        if (-not [string]::IsNullOrEmpty($default) -and $type -eq 'text') {
            Set-PlasterVariable -Name $name -Value $default -IsParam $true
            $PSCmdlet.WriteDebug("The condition of the parameter $($name) with the type 'text' evaluated to false. The parameter has a default value which will be used.")
        } else {
            # Define the parameter so later conditions can use it but its value will be $null
            Set-PlasterVariable -Name $name -Value $null -IsParam $true
            $PSCmdlet.WriteDebug("Skipping parameter $($name), condition evaluated to false.")
        }

        return
    }

    $prompt = Resolve-AttributeValue $Node.prompt (Get-ErrorLocationParameterAttrVal $name prompt)

    # Check if parameter was provided via a dynamic parameter.
    if ($script:boundParameters.ContainsKey($name)) {
        $value = $script:boundParameters[$name]
    } else {
        # Not a dynamic parameter so prompt user for the value but first check for a stored default value.
        if ($store -and ($null -ne $script:defaultValueStore[$name])) {
            $default = $script:defaultValueStore[$name]
            $PSCmdlet.WriteDebug("Read default value '$default' for parameter '$name' from default value store.")

            if (($store -eq 'encrypted') -and ($default -is [System.Security.SecureString])) {
                try {
                    $cred = New-Object -TypeName PSCredential -ArgumentList 'jsbplh', $default
                    $default = $cred.GetNetworkCredential().Password
                    $PSCmdlet.WriteDebug("Unencrypted default value for parameter '$name'.")
                } catch [System.Exception] {
                    Write-Warning ($LocalizedData.ErrorUnencryptingSecureString_F1 -f $name)
                }
            }
        }

        # If the prompt message failed to evaluate or was empty, supply a diagnostic prompt message
        if (!$prompt) {
            $prompt = $LocalizedData.MissingParameterPrompt_F1 -f $name
        }

        # Some default values might not come from the template e.g. some are harvested from .gitconfig if it exists.
        $defaultNotFromTemplate = $false

        $splat = @{}

        if ($null -ne $pattern) {
            $splat.Add('pattern', $pattern)
        }

        # Now prompt user for parameter value based on the parameter type.
        switch -regex ($type) {
            'text' {
                # Display an appropriate "default" value in the prompt string.
                if ($default) {
                    if ($store -eq 'encrypted') {
                        $obscuredDefault = $default -replace '(....).*', '$1****'
                        $prompt += " ($obscuredDefault)"
                    } else {
                        $prompt += " ($default)"
                    }
                }
                # Prompt the user for text input.
                $value = Read-PromptForInput $prompt $default @splat
                $valueToStore = $value
            }
            'user-fullname' {
                # If no default, try to get a name from git config.
                if (!$default) {
                    $default = Get-GitConfigValue('name')
                    $defaultNotFromTemplate = $true
                }

                if ($default) {
                    if ($store -eq 'encrypted') {
                        $obscuredDefault = $default -replace '(....).*', '$1****'
                        $prompt += " ($obscuredDefault)"
                    } else {
                        $prompt += " ($default)"
                    }
                }

                # Prompt the user for text input.
                $value = Read-PromptForInput $prompt $default @splat
                $valueToStore = $value
            }
            'user-email' {
                # If no default, try to get an email from git config
                if (-not $default) {
                    $default = Get-GitConfigValue('email')
                    $defaultNotFromTemplate = $true
                }

                if ($default) {
                    if ($store -eq 'encrypted') {
                        $obscuredDefault = $default -replace '(....).*', '$1****'
                        $prompt += " ($obscuredDefault)"
                    } else {
                        $prompt += " ($default)"
                    }
                }

                # Prompt the user for text input.
                $value = Read-PromptForInput $prompt $default @splat
                $valueToStore = $value
            }
            'choice|multichoice' {
                $choices = $Node.ChildNodes
                $defaults = [int[]]($default -split ',')

                # Prompt the user for choice or multichoice selection input.
                $selections = Read-PromptForChoice $name $choices $prompt $defaults -IsMultiChoice:($type -eq 'multichoice')
                $value = $selections.Values
                $OFS = ","
                $valueToStore = "$($selections.Indices)"
            }
            default { throw ($LocalizedData.UnrecognizedParameterType_F2 -f $type, $Node.LocalName) }
        }

        # If parameter specifies that user's input be stored as the default value,
        # store it to file if the value has changed.
        if ($store -and (($default -ne $valueToStore) -or $defaultNotFromTemplate)) {
            if ($store -eq 'encrypted') {
                $PSCmdlet.WriteDebug("Storing new, encrypted default value for parameter '$name' to default value store.")
                $script:defaultValueStore[$name] = ConvertTo-SecureString -String $valueToStore -AsPlainText -Force
            } else {
                $PSCmdlet.WriteDebug("Storing new default value '$valueToStore' for parameter '$name' to default value store.")
                $script:defaultValueStore[$name] = $valueToStore
            }

            $script:flags.DefaultValueStoreDirty = $true
        }
    }

    # Make template defined parameters available as a PowerShell variable PLASTER_PARAM_<parameterName>.
    Set-PlasterVariable -Name $name -Value $value -IsParam $true
}
