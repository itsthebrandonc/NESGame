$tile_Empty = 0
$tile_Grid = 1
$maxXTiles = 32
$maxYTiles = 30

$backgroundName = "background"
$gridPointSize_X = 4
$gridPointSize_Y = 4
$pointSize = 2

$output_backgroundTiles = "$($backgroundName): ; $gridPointSize_X x $gridPointSize_Y"
$output_gridPoints = "GRIDPOINTS: ; $gridPointSize_X x $gridPointSize_Y"
$array = [int[,]]::new(30, 32)
$gridPointCount = 0

$gridSpacing_X = [Math]::Floor($($maxXTiles - $gridPointSize_X) / ($gridPointSize_X - 1)) + 1
$gridSpacing_Y = [Math]::Floor($($maxYTiles - $gridPointSize_Y) / ($gridPointSize_Y - 1)) + 1

for ($row = 0; $row -lt 30; $row++)
{
    $gridRow = $row % $gridSpacing_Y -lt $pointSize

    for ($col = 0; $col -lt 32; $col++)
    {
        if ($row % $gridSpacing_Y -eq 0 -and $col % $gridSpacing_X -eq 0)
        {
            if ($gridPointCount % 8 -eq 0)
            {
                $output_gridPoints += "`n  .db "
            }

            $output_gridPoints += "`$"
            $output_gridPoints += $('{0:X}' -f $($col * 8)).ToString().PadLeft(2,'0')
            $output_gridPoints += ",`$"
            $output_gridPoints += $('{0:X}' -f $($row * 8)).ToString().PadLeft(2,'0')
            if ($($gridPointCount+1) % 8 -ne 0)
            {
                $output_gridPoints += ","
            }
            $gridPointCount += 1
        }

        $gridCol = ($gridRow) -and ($col % $gridSpacing_X -lt $pointSize)

        if ($gridCol)
        {
            $array[$row, $col] = $tile_Grid
        }
        else 
        {
            $array[$row, $col] = $tile_Empty        
        }

        if ($col -eq 0 -or $col -eq 16)
        {
            $output_backgroundTiles += "`n  .db "
        }
        $output_backgroundTiles += "`$$($($array[$row, $col]).ToString().PadLeft(2,'0'))"
        if ($col -ne 15 -and $col -ne 31)
        {
            $output_backgroundTiles += ","
        }
    }
    
    $output_backgroundTiles += "`n"
}

while ($gridPointCount % 8 -ne 0)
{
    $output_gridPoints += "`$00,`$00"
    if ($($gridPointCount+1) % 8 -ne 0)
    {
        $output_gridPoints += ","
    }
    $gridPointCount += 1
}

Clear-Host
Write-Host $output_backgroundTiles -ForegroundColor Green
Add-Content -Path "./BuildTools/output.txt" -Value "`n$output_backgroundTiles"

Write-Host "`n"
Write-Host $output_gridPoints -ForegroundColor Blue
Write-Host "`n"
Add-Content -Path "./BuildTools/output.txt" -Value $output_gridPoints

#Grid Points for spacing of 10
# (00,00) (50,00) (A0,00) (F0,00)
# (00,80) (50,80) (A0,80) (F0,80)
# 8*0=0, 8*10=80, 8*20=160, 8*30=240
# 256 max X, 240 max Y
# Max X = Ceil(256 / 80)? Max Y = Ceil(240 / 80)?
# 32 tiles X, 30 tiles Y

# To make a 4x4 grid, how can we determine that spacing is 10?
## A 4-wide row needs 4 grid tiles, 28 remaining
## Floor(28 / 3) required gaps = 9 between each
## 1 left at the end

# Given a dimension, how can we determine the max amount of gridpoints?
## 256 pixels across in X axis
## 258 - 8 = 248 reachable pixels for character
## 32 tiles, 31 reachable
## n grid tiles + (Floor(32-n / (n-1)) * (n-1)) <= 32