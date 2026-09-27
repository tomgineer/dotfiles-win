<#
.SYNOPSIS
Removes the password from a PDF and creates a new file with the suffix "-unlocked".
#>
function remove-pass {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$File,

        [Parameter(Mandatory, Position = 1)]
        [string]$Password
    )

    if (-not (Get-Command qpdf -ErrorAction SilentlyContinue)) {
        throw "qpdf was not found or is not available in PATH."
    }

    $inputFile = (Resolve-Path -LiteralPath $File).Path
    $directory = Split-Path -Parent $inputFile
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    $extension = [System.IO.Path]::GetExtension($inputFile)

    $outputFile = Join-Path $directory "$baseName-unlocked$extension"

    & qpdf "--password=$Password" --decrypt -- $inputFile $outputFile

    if ($LASTEXITCODE -ne 0) {
        throw "qpdf failed to remove the password from the PDF."
    }

    Write-Host "Unlocked PDF: $outputFile"
}