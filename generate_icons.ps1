Add-Type -AssemblyName System.Drawing

$iconDir = "assets/icons"
if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Path $iconDir | Out-Null }

$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

function New-RoundedRectPath([int]$x, [int]$y, [int]$w, [int]$h, [int]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-IconBitmap([int]$size) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    return @($bmp, $g)
}

# ── 1. icon_play.png (72x72 rounded play triangle) ───────────────────────────
$res = New-IconBitmap 72; $bmp = $res[0]; $g = $res[1]
$tri = New-Object System.Drawing.Drawing2D.GraphicsPath
$tri.AddPolygon(@(
    (New-Object System.Drawing.Point(20, 12)),
    (New-Object System.Drawing.Point(20, 60)),
    (New-Object System.Drawing.Point(60, 36))
))
$g.FillPath((New-Object System.Drawing.SolidBrush($white)), $tri)
$g.Dispose(); $bmp.Save("$iconDir/icon_play.png", [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

# ── 2. icon_grid.png (96x96 four rounded squares = level map) ────────────────
$res = New-IconBitmap 96; $bmp = $res[0]; $g = $res[1]
$brush = New-Object System.Drawing.SolidBrush($white)
foreach ($pos in @(@(10,10), @(50,10), @(10,50), @(50,50))) {
    $p = New-RoundedRectPath $pos[0] $pos[1] 36 36 9
    $g.FillPath($brush, $p)
}
$g.Dispose(); $bmp.Save("$iconDir/icon_grid.png", [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

# ── 3. icon_trophy.png (96x96 cup + handles + base) ──────────────────────────
$res = New-IconBitmap 96; $bmp = $res[0]; $g = $res[1]
$pen = New-Object System.Drawing.Pen($white, 7)
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
# handles
$g.DrawArc($pen, 8, 20, 22, 30, 120, 140)
$g.DrawArc($pen, 66, 20, 22, 30, 280, 140)
# cup body (tapered)
$cup = New-Object System.Drawing.Drawing2D.GraphicsPath
$cup.AddPolygon(@(
    (New-Object System.Drawing.Point(26, 14)),
    (New-Object System.Drawing.Point(70, 14)),
    (New-Object System.Drawing.Point(62, 42)),
    (New-Object System.Drawing.Point(54, 50)),
    (New-Object System.Drawing.Point(42, 50)),
    (New-Object System.Drawing.Point(34, 42))
))
$g.FillPath($brush, $cup)
# stem + base
$g.FillRectangle($brush, 43, 50, 10, 16)
$p = New-RoundedRectPath 30 66 36 10 5
$g.FillPath($brush, $p)
$g.Dispose(); $bmp.Save("$iconDir/icon_trophy.png", [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

# ── 4. icon_settings.png (96x96 three slider tracks + knobs) ─────────────────
$res = New-IconBitmap 96; $bmp = $res[0]; $g = $res[1]
$trackPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 8)
$trackPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$trackPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$rows = @(
    @(26, 34),
    @(48, 62),
    @(70, 40)
)
foreach ($row in $rows) {
    $y = $row[0]; $knobX = $row[1]
    $g.DrawLine($trackPen, 14, $y, 82, $y)
    $g.FillEllipse($brush, $knobX - 11, $y - 11, 22, 22)
}
$g.Dispose(); $bmp.Save("$iconDir/icon_settings.png", [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

# ── 5. panel_coral.png (512x140 vertical coral gradient, rounded r=44) ───────
$bmp = New-Object System.Drawing.Bitmap(512, 140)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$path = New-RoundedRectPath 2 2 508 136 44
$gradRect = New-Object System.Drawing.Rectangle(2, 2, 508, 136)
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $gradRect,
    [System.Drawing.Color]::FromArgb(255, 255, 143, 105),   # warm coral top
    [System.Drawing.Color]::FromArgb(255, 240, 74, 122),    # deep coral-pink bottom
    90.0)
$g.FillPath($grad, $path)
# subtle glossy top rim
$rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 255, 255, 255), 4)
$rim = New-RoundedRectPath 6 6 500 66 40
$g.DrawPath($rimPen, $rim)
$g.Dispose(); $bmp.Save("$iconDir/panel_coral.png", [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

Write-Output "Icons generated in $iconDir"
