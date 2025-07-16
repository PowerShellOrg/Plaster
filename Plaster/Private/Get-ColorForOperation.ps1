function Get-ColorForOperation {
    param(
        $operation
    )
    switch ($operation) {
        $LocalizedData.OpConflict      { 'Red' }
        $LocalizedData.OpCreate        { 'Green' }
        $LocalizedData.OpForce         { 'Yellow' }
        $LocalizedData.OpIdentical     { 'Cyan' }
        $LocalizedData.OpModify        { 'Magenta' }
        $LocalizedData.OpUpdate        { 'Green' }
        $LocalizedData.OpMissing       { 'Red' }
        $LocalizedData.OpVerify        { 'Green' }
        default { $Host.UI.RawUI.ForegroundColor }
    }
}
