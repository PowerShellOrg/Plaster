function New-BackupFilename {
    [CmdletBinding()]
    param(
        [string]$Path
    )
    $dir = [System.IO.Path]::GetDirectoryName($Path)
    $filename = [System.IO.Path]::GetFileName($Path)
    $backupPath = Join-Path -Path $dir -ChildPath "${filename}.bak"
    $i = 1
    while (Test-Path -LiteralPath $backupPath) {
        $backupPath = Join-Path -Path $dir -ChildPath "${filename}.bak$i"
        $i++
    }

    $backupPath
}
