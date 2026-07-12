<#
.SYNOPSIS
Sums receipt amounts from filenames like dd.MM.yyyy_shop_00.00.JPG and writes a monthly summary file.
#>
function write-sum {
    $Path = (Get-Location).Path

    $AllowedShops = @(
        # Supermarkets / discounters
        "aldi",
        "rewe",
        "edeka",
        "lidl",
        "netto",
        "kaufland",
        "penny",

        # Drogerie
        "dm",
        "rossmann",
        "mueller",

        # Generic fallback
        "others"
    )

    $Pattern = '^(\d{2})\.(\d{2})\.(\d{4})_([a-zA-Z]+)_([0-9]+\.[0-9]{2})$'

    $Files = Get-ChildItem -Path $Path -File |
        Where-Object {
            $_.Extension -match '^\.(jpg|jpeg|png|webp|heic)$'
        }

    $Receipts = foreach ($File in $Files) {
        $Name = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)

        if ($Name -match $Pattern) {
            $Day = $Matches[1]
            $Month = $Matches[2]
            $Year = $Matches[3]
            $Shop = $Matches[4].ToLower()
            $AmountText = $Matches[5]

            if ($AllowedShops -notcontains $Shop) {
                Write-Warning "Ignored unknown shop: $($File.Name)"
                continue
            }

            $Amount = [decimal]::Parse(
                $AmountText,
                [System.Globalization.CultureInfo]::InvariantCulture
            )

            [PSCustomObject]@{
                File = $File.Name
                Date = "$Day.$Month.$Year"
                Month = "$Month.$Year"
                Shop = $Shop
                Amount = $Amount
            }
        }
        else {
            Write-Warning "Ignored invalid filename: $($File.Name)"
        }
    }

    if (-not $Receipts) {
        Write-Host "No valid receipt files found."
        return
    }

    $Months = $Receipts.Month | Sort-Object -Unique

    foreach ($ReceiptMonth in $Months) {
        $MonthReceipts = $Receipts | Where-Object {
            $_.Month -eq $ReceiptMonth
        }

        $OutputFile = Join-Path $Path "sum_$ReceiptMonth.txt"

        $ShopSums = $MonthReceipts |
            Group-Object Shop |
            Sort-Object Name |
            ForEach-Object {
                [PSCustomObject]@{
                    Shop = $_.Name
                    Sum = ($_.Group | Measure-Object Amount -Sum).Sum
                    Count = $_.Count
                }
            }

        $Total = ($MonthReceipts | Measure-Object Amount -Sum).Sum

        $Lines = @()
        $Lines += "Receipt Sum $ReceiptMonth"
        $Lines += "=================="
        $Lines += ""
        $Lines += "Folder: $Path"
        $Lines += "Created: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')"
        $Lines += ""
        $Lines += "By shop:"
        $Lines += ""

        foreach ($Item in $ShopSums) {
            $Lines += ("{0,-15} {1,8:N2} EUR  ({2} receipts)" -f $Item.Shop, $Item.Sum, $Item.Count)
        }

        $Lines += ""
        $Lines += "------------------------------"
        $Lines += ("Total:          {0,8:N2} EUR" -f $Total)
        $Lines += ""
        $Lines += "Files:"
        $Lines += ""

        foreach ($Receipt in ($MonthReceipts | Sort-Object Date, Shop, File)) {
            $Lines += ("{0,-45} {1,8:N2} EUR" -f $Receipt.File, $Receipt.Amount)
        }

        $Lines | Set-Content -Path $OutputFile -Encoding UTF8

        Write-Host ""
        Write-Host "Written: $OutputFile"
        Write-Host ""
        Write-Host "By shop:"
        $ShopSums | Format-Table Shop, Count, Sum -AutoSize
        Write-Host ("Total: {0:N2} EUR" -f $Total)
    }
}