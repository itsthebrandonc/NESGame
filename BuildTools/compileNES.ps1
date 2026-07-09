$projectName = Split-Path -Path $PWD -Leaf

$rom = Get-ChildItem -Name -Path "./Build/$projectName.nes" -ErrorAction SilentlyContinue
if ($rom)
{
    Move-Item "./Build/$rom" -Destination "./Backup/$projectName.bck" -Force
}
$source = Get-ChildItem -Name "$projectName.asm"
if (!$source)
{
    $source = Get-ChildItem -Name -Include *.s
}

Write-Host "`n========================`nCompiling $projectName...`n========================`n" -ForegroundColor Green

Start-Process -FilePath "./BuildTools/NESASM3.exe" -ArgumentList "$PWD`\$source" -Wait

Remove-Item * -Include *.fns

$rom = Get-ChildItem -Name -Include *.nes
if (!$rom)
{
    Write-Host "`n========================`nROM Failed`n========================`n" -ForegroundColor Red
    Copy-Item -Path "./BuildTools/NESASM3.exe" -Destination "./NESASM3.exe" -Force
    $bat = Get-ChildItem  -Path "./BuildTools" -Name -Include *.bat
    Start-Process -FilePath "./BuildTools/$bat" -ArgumentList "$projectName.asm" -Wait
    Remove-Item -Path "./NESASM3.exe"
}
else
{
    Write-Host "`n========================`nROM Compiled`n========================`n" -ForegroundColor Green
    Move-Item -Path $rom -Destination "./Build/$projectName.nes" -Force
    Copy-Item -Path "./Build/$projectName.nes" -Destination "./Backup/$projectName.nes" -Force
    Copy-Item -Path $source -Destination "./Backup/" -Force
    Get-ChildItem -Name -Include *.asm | Copy-Item -Destination "./Backup/" -Force
    if (Get-Process -Name "fceuxdsp" -ErrorAction SilentlyContinue)
    {
        Stop-Process -Name "fceuxdsp" -Force
    }
    Invoke-Item "./Build/$rom"
}