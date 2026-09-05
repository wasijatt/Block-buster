Add-Type -AssemblyName System.Drawing

# 1. Generate particle_block.png (32x32 smooth rounded square)
$bmpParticle = New-Object System.Drawing.Bitmap(32, 32)
$g = [System.Drawing.Graphics]::FromImage($bmpParticle)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$r = 6
$d = $r * 2
$rect = New-Object System.Drawing.Rectangle(2, 2, 28, 28)
$path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
$path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
$path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
$path.CloseFigure()

# Fill with soft white / light teal gem tone with slight alpha so particles blend nicely
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 245, 255, 255))
$g.FillPath($brush, $path)

# Subtle inner highlight / border
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1.5)
$g.DrawPath($pen, $path)

$g.Dispose()
$bmpParticle.Save("assets/particle_block.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpParticle.Dispose()

# 2. Generate logo.png (400x160 vibrant game logo placeholder)
$bmpLogo = New-Object System.Drawing.Bitmap(400, 160)
$g2 = [System.Drawing.Graphics]::FromImage($bmpLogo)
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g2.Clear([System.Drawing.Color]::Transparent)

# Background badge pill
$bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$bgr = 24
$bgd = $bgr * 2
$bgRect = New-Object System.Drawing.Rectangle(10, 10, 380, 140)
$bgPath.AddArc($bgRect.X, $bgRect.Y, $bgd, $bgd, 180, 90)
$bgPath.AddArc($bgRect.Right - $bgd, $bgRect.Y, $bgd, $bgd, 270, 90)
$bgPath.AddArc($bgRect.Right - $bgd, $bgRect.Bottom - $bgd, $bgd, $bgd, 0, 90)
$bgPath.AddArc($bgRect.X, $bgRect.Bottom - $bgd, $bgd, $bgd, 90, 90)
$bgPath.CloseFigure()

$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect, [System.Drawing.Color]::FromArgb(245, 32, 26, 58), [System.Drawing.Color]::FromArgb(245, 16, 14, 32), 90.0)
$g2.FillPath($bgBrush, $bgPath)
$borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(230, 255, 195, 60), 4)
$g2.DrawPath($borderPen, $bgPath)

# Logo Text
$font = New-Object System.Drawing.Font("Arial", 30, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center

# Shadow
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
$g2.DrawString("BLOCK BUSTER", $font, $shadowBrush, [System.Drawing.RectangleF]::new(13, 33, 380, 60), $format)

# Main gold text
$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 205, 50))
$g2.DrawString("BLOCK BUSTER", $font, $goldBrush, [System.Drawing.RectangleF]::new(10, 30, 380, 60), $format)

# Subtitle
$subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 80, 230, 160))
$g2.DrawString("PUZZLE ADVENTURE", $subFont, $subBrush, [System.Drawing.RectangleF]::new(10, 95, 380, 30), $format)

$g2.Dispose()
$bmpLogo.Save("assets/logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpLogo.Dispose()

Write-Host "Generated assets/particle_block.png and assets/logo.png successfully!"
