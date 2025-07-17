function Test-JsonManifestParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Parameters
    )

    $parameterNames = @()

    foreach ($param in $Parameters) {
        # Required properties
        if (-not $param.name -or -not $param.type) {
            throw "Parameter missing required 'name' or 'type' property"
        }

        # Validate parameter name pattern
        if ($param.name -notmatch '^[A-Za-z][A-Za-z0-9_]*$') {
            throw "Invalid parameter name: $($param.name). Must start with letter and contain only letters, numbers, or underscore"
        }

        # Check for duplicate parameter names
        if ($param.name -in $parameterNames) {
            throw "Duplicate parameter name: $($param.name)"
        }
        $parameterNames += $param.name

        # Validate parameter type
        $validTypes = @('text', 'user-fullname', 'user-email', 'choice', 'multichoice', 'switch')
        if ($param.type -notin $validTypes) {
            throw "Invalid parameter type: $($param.type). Valid types: $($validTypes -join ', ')"
        }

        # Choice parameters must have choices
        if ($param.type -in @('choice', 'multichoice') -and -not $param.choices) {
            throw "Parameter '$($param.name)' of type '$($param.type)' must have 'choices' property"
        }

        # Validate choices if present
        if ($param.choices) {
            foreach ($choice in $param.choices) {
                if (-not $choice.label -or -not $choice.value) {
                    throw "Choice in parameter '$($param.name)' missing required 'label' or 'value' property"
                }
            }
        }

        # Validate dependsOn references
        if ($param.dependsOn) {
            foreach ($dependency in $param.dependsOn) {
                if ($dependency -notin $parameterNames -and $dependency -ne $param.name) {
                    # Note: We'll validate this after processing all parameters
                    Write-PlasterLog -Level Debug -Message "Parameter '$($param.name)' depends on '$dependency'"
                }
            }
        }

        # Validate condition syntax if present
        if ($param.condition) {
            Test-PlasterCondition -Condition $param.condition -ParameterName $param.name
        }
    }
}
