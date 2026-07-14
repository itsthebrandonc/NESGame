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

$startTime = Get-Date
Start-Process -FilePath "./BuildTools/NESASM3.exe" -ArgumentList "$PWD`\$source" -Wait
$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalMilliseconds

Remove-Item * -Include *.fns

$rom = Get-ChildItem -File "$projectName.nes" | Select-Object Name, @{Name="Size"; Expression={[Math]::Round($_.Length / 1KB, 2)}}
if (!$rom)
{
    Write-Host "`n========================`nROM Failed`n========================`n" -ForegroundColor Red
    Copy-Item -Path "./BuildTools/NESASM3.exe" -Destination "./NESASM3.exe" -Force
    $bat = Get-ChildItem  -Path "./BuildTools" -Name -Include *.bat
    Start-Process -FilePath "./BuildTools/$bat" -ArgumentList "$projectName.asm" -Wait
    Remove-Item -Path "./NESASM3.exe"
    Remove-Item -Path "./$projectName.fns"
}
else
{
    Write-Host "`n========================`nROM Compiled`n========================" -ForegroundColor Green

    $buildInfo = Get-Content -Path "./README.md"
    $versionLine = $buildInfo[1]
    $versionNumbers = $versionLine -split "\."
    $buildNumber = [int]$($versionNumbers | Select-Object -Last 1)
    $buildNumber += 1
    $versionLine = "$($versionNumbers[0]).$($versionNumbers[1]).$($versionNumbers[2]).$($versionNumbers[3]).$($buildNumber)"
    $buildInfo[1] = $versionLine
    $buildInfo[2] = "### $($rom.Size) KB"
    $buildInfo | Out-File -FilePath "./README.md"


    Write-Host "v.$($versionNumbers[1]).$($versionNumbers[2]).$($versionNumbers[3]).$($buildNumber)" -ForegroundColor Green
    Write-Host "$($rom.Size) KB" -ForegroundColor Green
    Write-Host "Compilation time: $totalTime ms`n" -ForegroundColor Green

    Move-Item -Path $($rom.Name) -Destination "./Build/$projectName.nes" -Force
    Copy-Item -Path "./Build/$projectName.nes" -Destination "./Backup/$projectName.nes" -Force
    Copy-Item -Path $source -Destination "./Backup/" -Force
    Remove-Item -Path "./$projectName.fns" -ErrorAction SilentlyContinue
    Get-ChildItem -Name -Include *.asm | Copy-Item -Destination "./Backup/" -Force
    if (Get-Process -Name "fceuxdsp" -ErrorAction SilentlyContinue)
    {
        Stop-Process -Name "fceuxdsp" -Force
    }
    Invoke-Item "./Build/$($rom.Name)"
}