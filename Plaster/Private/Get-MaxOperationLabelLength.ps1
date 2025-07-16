function Get-MaxOperationLabelLength {
    ($LocalizedData.OpCreate, $LocalizedData.OpIdentical,
    $LocalizedData.OpConflict, $LocalizedData.OpForce,
    $LocalizedData.OpMissing, $LocalizedData.OpModify,
    $LocalizedData.OpUpdate, $LocalizedData.OpVerify |
        Measure-Object -Property Length -Maximum).Maximum
}
