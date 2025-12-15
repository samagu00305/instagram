$content = Get-Content -Path 'Util.ahk' -Encoding UTF8
$Utf8BomEncoding = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines((Resolve-Path 'Util.ahk'), $content, $Utf8BomEncoding)

$content = Get-Content -Path 'GlobalData.ahk' -Encoding UTF8
[System.IO.File]::WriteAllLines((Resolve-Path 'GlobalData.ahk'), $content, $Utf8BomEncoding)

Write-Host "Done!"
