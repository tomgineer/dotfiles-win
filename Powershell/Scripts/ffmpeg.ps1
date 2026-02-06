<#
.SYNOPSIS
Creates midpoint WebP thumbnails for videos in the current folder.
#>
function videothumbs {

    $videoExt = @('*.mp4','*.mkv','*.mov','*.avi','*.wmv','*.m4v','*.webm','*.flv','*.mpg')
    $cwd = Get-Location
    $thumbDir = Join-Path $cwd 'thumbs'

    if (-not (Test-Path $thumbDir)) {
        New-Item -ItemType Directory -Path $thumbDir | Out-Null
    }

    $ffmpeg  = (Get-Command ffmpeg  -ErrorAction Stop).Source
    $ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source

    foreach ($ext in $videoExt) {
        Get-ChildItem -File -Filter $ext | ForEach-Object {

            $video = $_
            $out   = Join-Path $thumbDir ($video.BaseName + '.webp')

            if (Test-Path $out) {
                return
            }

            $duration = & $ffprobe `
                -v error `
                -show_entries format=duration `
                -of default=nk=1:nw=1 `
                "$($video.FullName)"

            if (-not $duration) {
                Write-Warning "Skipping (no duration): $($video.Name)"
                return
            }

            $mid = ([double]$duration / 2).ToString("0.###", [cultureinfo]::InvariantCulture)

            & $ffmpeg -hide_banner -loglevel error `
                -ss $mid -i "$($video.FullName)" `
                -frames:v 1 -an `
                -vf "scale='min(1920,iw)':-2" `
                -c:v libwebp -quality 85 `
                -y "$out"

            if (Test-Path $out) {
                Write-Host "✔ $($video.Name)"
            } else {
                Write-Warning "✖ Failed: $($video.Name)"
            }
        }
    }
}

<#
.SYNOPSIS
Extracts video metadata with ffprobe and saves one JSON file per video.
#>
function videometa {
    # Ensure ffprobe exists
    try {
        & ffprobe -version *> $null
    } catch {
        throw "ffprobe not found in PATH. Install ffmpeg or add it to PATH."
    }

    $cwd = (Get-Location).Path
    $metaDir = Join-Path $cwd "meta"

    if (-not (Test-Path $metaDir)) {
        New-Item -ItemType Directory -Path $metaDir | Out-Null
    }

    $extensions = @("mp4","mkv","mov","avi","webm","m4v","ts","mts")

    $videos = Get-ChildItem -Path $cwd -File |
        Where-Object {
            $ext = $_.Extension.TrimStart(".").ToLowerInvariant()
            $extensions -contains $ext
        }

    foreach ($f in $videos) {
        $outJson = Join-Path $metaDir ($f.BaseName + ".json")
        if (Test-Path $outJson) { continue }

        $probeJson = & ffprobe -v error -print_format json -show_format -show_streams "$($f.FullName)"
        if (-not $probeJson) { continue }

        $probe = $probeJson | ConvertFrom-Json
        $vs = $probe.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        if (-not $vs) { continue }

        # Rotation (iPhone often uses rotate tag or Display Matrix side data)
        $rotation = 0

        if ($vs.tags -and $vs.tags.rotate) {
            [int]::TryParse([string]$vs.tags.rotate, [ref]$rotation) | Out-Null
        } elseif ($vs.side_data_list) {
            $dm = $vs.side_data_list | Where-Object { $_.side_data_type -match "Display Matrix" } | Select-Object -First 1
            if ($dm -and $dm.rotation) {
                [int]::TryParse([string]$dm.rotation, [ref]$rotation) | Out-Null
            }
        }

        $rotation = (($rotation % 360) + 360) % 360

        # Final width/height (rotation-aware)
        $width  = [int]$vs.width
        $height = [int]$vs.height

        if ($rotation -eq 90 -or $rotation -eq 270) {
            $tmp = $width
            $width = $height
            $height = $tmp
        }

        $fps = $null
        if ($vs.avg_frame_rate -and $vs.avg_frame_rate -ne "0/0") {
            $p = $vs.avg_frame_rate.Split("/")
            if ($p.Count -eq 2 -and [double]$p[1] -ne 0) {
                $fps = [double]$p[0] / [double]$p[1]
            }
        }

        # Date
        $dateRaw = $null
        if ($probe.format.tags) {
            if ($probe.format.tags.creation_time) {
                $dateRaw = $probe.format.tags.creation_time
            } elseif ($probe.format.tags."com.apple.quicktime.creationdate") {
                $dateRaw = $probe.format.tags."com.apple.quicktime.creationdate"
            }
        }
        if (-not $dateRaw -and $vs.tags -and $vs.tags.creation_time) {
            $dateRaw = $vs.tags.creation_time
        }

        $created =
            if ($dateRaw) {
                try {
                    [DateTimeOffset]::Parse([string]$dateRaw).ToUniversalTime().ToString("o")
                } catch {
                    [string]$dateRaw
                }
            } else {
                $f.CreationTimeUtc.ToString("o")
            }

        $meta = [ordered]@{
            file       = $f.Name
            created    = $created
            duration_s = [double]$probe.format.duration
            container  = $probe.format.format_name
            video = [ordered]@{
                codec  = $vs.codec_name
                width  = $width
                height = $height
                fps    = $fps
            }
        }

        $meta | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $outJson

        Write-Host "✔ $($f.Name) ${width}x${height} (rot $rotation)"
    }
}
