function Test-FilesIdentical($Path1, $Path2) {
    $file1 = Get-Item -LiteralPath $Path1 -Force
    $file2 = Get-Item -LiteralPath $Path2 -Force

    if ($file1.Length -ne $file2.Length) {
        return $false
    }

    $hash1 = (Get-FileHash -LiteralPath $path1 -Algorithm SHA1).Hash
    $hash2 = (Get-FileHash -LiteralPath $path2 -Algorithm SHA1).Hash

    $hash1 -eq $hash2
}
