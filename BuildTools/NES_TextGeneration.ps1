$startHex = 16 #$10
$charArray = @("0","1","2","3","4","5","6","7","8","9","!","?","^","","","","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")

$string = "Testing maximum string length ^"
if ($string -eq "")
{
    $string = Read-Host "Enter Text"
}

function ConvertTo-PascalCase {
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$InputString
    )
    process {
        # Standardize separators to spaces, lower everything, title case, then join
        $CleanString = $InputString.ToLower() -replace '[^0-9a-zA-Z]', ' '
        return (Get-Culture).TextInfo.ToTitleCase($CleanString) -replace ' ', ''
    }
}

$string = $string.ToUpper()

# 1 row = 32 tiles
if ($string.Length -eq 0)
{
    # Blank row
}
if ($string.Length -gt 32)
{
    # Need to split string across multiple rows
}
else
{

    $stringCenter = [Math]::Floor($($string.Length) / 2) - 1
    $leftString = $string.Substring(0,$stringCenter+1)
    $rightString = $string.Substring($stringCenter+1)
    
    $leftStart = 16 - $($leftString.Length)
    $rightEnd = 16 + $($rightString.Length) - 1

    $hexRow = " .db "
    for ($i = 0; $i -lt 32; $i++)
    {
        $char = " "
        $hexCode = "00"
        if (($i -ge $leftStart) -and ($i -le $rightEnd))
        {
            $char = $string.Substring($i-$leftStart,1)
            if ($char -ne " ")
            {
                $hexCode = $($charArray.IndexOf($char) + $startHex).ToString("X")
            }
        }

        Write-Host "$char : `$$hexCode"
        $hexRow += "`$$hexCode"
        if (($i -ne 15) -and ($i -ne 31))
        {
            $hexRow += ","
        }
        if ($i -eq 15)
        {
            $hexRow += "`n .db "
        }
    }

    Write-Host "`n`n`n"
    Write-Host "textRow_$($string | ConvertTo-PascalCase):"
    Write-Host "$hexRow ; $string"
}

#tileRow_HelloWorld:
#  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$27,$24,$2B,$2B,$2E,$00,$36
#  .db $2E,$31,$2B,$23,$1A,$00,$1C,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;.db cannot handle 32 values on one line, for some reason

#Testing maximum string length 