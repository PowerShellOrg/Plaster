function Resolve-ProcessParameter {
    [CmdletBinding()]
    param(
        [ValidateNotNull()]$Node
    )

    $name = $Node.name
    $type = $Node.type
    $store = $Node.store
    $pattern = $Node.pattern  # New for JSON format
    $condition = $Node.condition

    $default = Resolve-AttributeValue $Node.default (GetErrorLocationParameterAttrVal $name default)

    # Enhanced condition evaluation with JSON support
    if ($condition -and !(EvaluateConditionAttribute $condition "'<$($Node.LocalName)>'")) {
        if (-not [string]::IsNullOrEmpty($default) -and $type -eq 'text') {
            Set-PlasterVariable -Name $name -Value $default -IsParam $true
            $PSCmdlet.WriteDebug("Parameter $($name) condition false, using default: $default")
        } else {
            Set-PlasterVariable -Name $name -Value $null -IsParam $true
            $PSCmdlet.WriteDebug("Skipping parameter $($name), condition evaluated to false.")
        }
        return
    }

    $prompt = Resolve-AttributeValue $Node.prompt (GetErrorLocationParameterAttrVal $name prompt)

    # Check for dynamic parameter value
    if ($boundParameters.ContainsKey($name)) {
        $value = $boundParameters[$name]

        # Enhanced validation for JSON parameters
        if ($pattern -and $type -eq 'text' -and $value -notmatch $pattern) {
            $validationMessage = if ($Node.validationMessage) { $Node.validationMessage } else { "Value does not match required pattern: $pattern" }
            throw "Parameter '$name' validation failed: $validationMessage"
        }

        Write-PlasterLog -Level Debug -Message "Using dynamic parameter value for '$name': $value"
    } else {
        # Interactive parameter collection with enhanced validation
        # ... (rest of parameter processing logic)
    }

    # Make template defined parameters available as PowerShell variables
    Set-PlasterVariable -Name $name -Value $value -IsParam $true
    Write-PlasterLog -Level Debug -Message "Set parameter variable: PLASTER_PARAM_$name = $value"
}
