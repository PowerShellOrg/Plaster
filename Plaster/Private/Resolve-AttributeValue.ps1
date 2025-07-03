function Resolve-AttributeValue {
    [CmdletBinding()]
    param(
        [string]$Value,
        [string]$Location
    )

    if ($null -eq $Value) {
        return [string]::Empty
    }
    elseif ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    try {
        # Handle both XML-style ${PLASTER_PARAM_Name} and JSON-style ${Name} variables
        if ($manifestType -eq 'JSON') {
            # Convert JSON-style variables to XML-style for processing
            $Value = $Value -replace '\$\{(?!PLASTER_)([A-Za-z][A-Za-z0-9_]*)\}', '${PLASTER_PARAM_$1}'
        }

        $res = @(ExecuteExpressionImpl "`"$Value`"")
        [string]$res[0]
    }
    catch {
        throw ($LocalizedData.InterpolationError_F3 -f $Value.Trim(),$Location,$_)
    }
}
