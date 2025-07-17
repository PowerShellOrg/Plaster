function Test-JsonManifestContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Content
    )

    if ($Content.Count -eq 0) {
        throw "Content section cannot be empty"
    }

    foreach ($action in $Content) {
        if (-not $action.type) {
            throw "Content action missing required 'type' property"
        }

        # Validate action type and required properties
        switch ($action.type) {
            'message' {
                if (-not $action.text) {
                    throw "Message action missing required 'text' property"
                }
            }
            'file' {
                if (-not $action.source -or -not $action.destination) {
                    throw "File action missing required 'source' or 'destination' property"
                }
            }
            'templateFile' {
                if (-not $action.source -or -not $action.destination) {
                    throw "TemplateFile action missing required 'source' or 'destination' property"
                }
            }
            'directory' {
                if (-not $action.destination) {
                    throw "Directory action missing required 'destination' property"
                }
            }
            'newModuleManifest' {
                if (-not $action.destination) {
                    throw "NewModuleManifest action missing required 'destination' property"
                }
            }
            'modify' {
                if (-not $action.path -or -not $action.modifications) {
                    throw "Modify action missing required 'path' or 'modifications' property"
                }

                # Validate modifications
                foreach ($modification in $action.modifications) {
                    if (-not $modification.type) {
                        throw "Modification missing required 'type' property"
                    }

                    if ($modification.type -eq 'replace') {
                        if (-not $modification.PSObject.Properties['search'] -or -not $modification.PSObject.Properties['replace']) {
                            throw "Replace modification missing required 'search' or 'replace' property"
                        }
                    }
                }
            }
            'requireModule' {
                if (-not $action.name) {
                    throw "RequireModule action missing required 'name' property"
                }
            }
            'execute' {
                if (-not $action.script) {
                    throw "Execute action missing required 'script' property"
                }
            }
            default {
                throw "Unknown content action type: $($action.type)"
            }
        }

        # Validate condition if present
        if ($action.condition) {
            Test-PlasterCondition -Condition $action.condition -Context "Content action ($($action.type))"
        }
    }
}
