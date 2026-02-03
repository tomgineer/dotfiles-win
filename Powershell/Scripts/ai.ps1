# Shows predefined image dimensions grouped by aspect ratio in a colorized table.

function dim {

    $square   = @("768 x 768", "1024 x 1024", "1536 x 1536")
    $wide169  = @("1280 x 720", "1536 x 864", "1920 x 1080")
    $ratio43  = @("1024 x 768", "1152 x 864", "1440 x 1080")
    $vertical = @("720 x 1280", "864 x 1536", "1080 x 1920")

    $h = "─" * 13

    Write-Host ""
    Write-Host "┌$h┬$h┬$h┬$h┐" -ForegroundColor Blue

    Write-Host "│" -NoNewline -ForegroundColor Blue
    Write-Host ("{0,-13}" -f " Square") -NoNewline -ForegroundColor Gray
    Write-Host "│" -NoNewline -ForegroundColor Blue
    Write-Host ("{0,-13}" -f " 16:9") -NoNewline -ForegroundColor Gray
    Write-Host "│" -NoNewline -ForegroundColor Blue
    Write-Host ("{0,-13}" -f " 4:3") -NoNewline -ForegroundColor Gray
    Write-Host "│" -NoNewline -ForegroundColor Blue
    Write-Host ("{0,-13}" -f " Vertical") -NoNewline -ForegroundColor Gray
    Write-Host "│" -ForegroundColor Blue

    Write-Host "├$h┼$h┼$h┼$h┤" -ForegroundColor Blue

    for ($i = 0; $i -lt 3; $i++) {

        Write-Host "│" -NoNewline -ForegroundColor Blue
        Write-Host ("{0,-13}" -f (" " + $square[$i])) -NoNewline -ForegroundColor Gray
        Write-Host "│" -NoNewline -ForegroundColor Blue
        Write-Host ("{0,-13}" -f (" " + $wide169[$i])) -NoNewline -ForegroundColor Gray
        Write-Host "│" -NoNewline -ForegroundColor Blue
        Write-Host ("{0,-13}" -f (" " + $ratio43[$i])) -NoNewline -ForegroundColor Gray
        Write-Host "│" -NoNewline -ForegroundColor Blue
        Write-Host ("{0,-13}" -f (" " + $vertical[$i])) -NoNewline -ForegroundColor Gray
        Write-Host "│" -ForegroundColor Blue
    }

    Write-Host "└$h┴$h┴$h┴$h┘" -ForegroundColor Blue
}
