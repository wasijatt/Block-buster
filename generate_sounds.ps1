$sampleRate = 44100

function Create-Wav($filename, $samples) {
    $bytes = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($bytes)
    
    $dataSize = $samples.Length * 2
    $chunkSize = 36 + $dataSize
    
    # RIFF header
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write([int32]$chunkSize)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    
    # fmt chunk
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $writer.Write([int32]16) # Subchunk1Size (16 for PCM)
    $writer.Write([int16]1)  # AudioFormat (1 = PCM)
    $writer.Write([int16]1)  # NumChannels (1 = Mono)
    $writer.Write([int32]$sampleRate)
    $writer.Write([int32]($sampleRate * 2)) # ByteRate
    $writer.Write([int16]2)  # BlockAlign
    $writer.Write([int16]16) # BitsPerSample
    
    # data chunk
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write([int32]$dataSize)
    
    foreach ($sample in $samples) {
        $val = [int16][Math]::Max(-32767.0, [Math]::Min(32767.0, [double]$sample))
        $writer.Write($val)
    }
    
    $writer.Close()
    [System.IO.File]::WriteAllBytes($filename, $bytes.ToArray())
}

# Helper to clamp safely
function Clamp-Sample($v) {
    return [Math]::Max(-32767.0, [Math]::Min(32767.0, [double]$v))
}

# 1. CLICK / UI POP (Crisp bouncy pop)
$dur = 0.08
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $env = [Math]::Pow(1.0 - ($i / $count), 2.5)
    $freq = 600 + 800 * (1.0 - ($i / $count))
    $val = [Math]::Sin(2 * [Math]::PI * $freq * $t) * 0.7 + [Math]::Sin(4 * [Math]::PI * $freq * $t) * 0.2
    $samples[$i] = Clamp-Sample ($val * $env * 24000)
}
Create-Wav "sounds/click.wav" $samples

# 2. PICKUP (Bright airy upward swoosh)
$dur = 0.12
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $prog = $i / $count
    $env = [Math]::Sin($prog * [Math]::PI)
    $freq = 420 + 500 * $prog
    $val = [Math]::Sin(2 * [Math]::PI * $freq * $t) * 0.6 + [Math]::Sin(2 * [Math]::PI * ($freq * 1.5) * $t) * 0.25
    $samples[$i] = Clamp-Sample ($val * $env * 22000)
}
Create-Wav "sounds/pickup.wav" $samples

# 3. DROP / SNAP (Punchy solid wooden/gem placement thud)
$dur = 0.14
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $env = [Math]::Exp(-$t * 40)
    $freq = 240 * [Math]::Exp(-$t * 24) + 90
    $sub = [Math]::Sin(2 * [Math]::PI * $freq * $t) * 0.75
    $click = [Math]::Sin(2 * [Math]::PI * 1800 * $t) * [Math]::Exp(-$t * 120) * 0.25
    $samples[$i] = Clamp-Sample (($sub + $click) * $env * 26000)
}
Create-Wav "sounds/drop.wav" $samples

# 4. CLEAR / LINE CHIME (Sparkling lush C-major arpeggio chime)
$dur = 0.65
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
$notes = @(523.25, 659.25, 783.99, 1046.50) # C5, E5, G5, C6
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $mix = 0.0
    for ($n = 0; $n -lt $notes.Length; $n++) {
        $startTime = $n * 0.045
        if ($t -ge $startTime) {
            $noteT = $t - $startTime
            $noteEnv = [Math]::Exp(-$noteT * 7.5)
            $f = $notes[$n]
            $tone = [Math]::Sin(2 * [Math]::PI * $f * $noteT) * 0.5 + [Math]::Sin(2 * [Math]::PI * ($f * 2) * $noteT) * 0.2 + [Math]::Sin(2 * [Math]::PI * ($f * 3) * $noteT) * 0.1
            $mix += $tone * $noteEnv
        }
    }
    $samples[$i] = Clamp-Sample ($mix * 17000)
}
Create-Wav "sounds/clear.wav" $samples

# 5. COMBO / STREAK (High shimmering celebratory chord)
$dur = 0.8
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
$comboNotes = @(587.33, 739.99, 880.0, 1174.66, 1479.98) # D major 9th sparkle
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $mix = 0.0
    for ($n = 0; $n -lt $comboNotes.Length; $n++) {
        $startTime = $n * 0.04
        if ($t -ge $startTime) {
            $noteT = $t - $startTime
            $noteEnv = [Math]::Exp(-$noteT * 6.0)
            $f = $comboNotes[$n]
            $tone = [Math]::Sin(2 * [Math]::PI * $f * $noteT) * 0.45 + [Math]::Sin(2 * [Math]::PI * ($f * 2) * $noteT) * 0.25 + [Math]::Sin(2 * [Math]::PI * ($f * 4) * $noteT) * 0.1
            $mix += $tone * $noteEnv
        }
    }
    $samples[$i] = Clamp-Sample ($mix * 15000)
}
Create-Wav "sounds/combo.wav" $samples

# 6. BADGE / ACHIEVEMENT (Magical glockenspiel shimmer)
$dur = 0.95
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
$badgeNotes = @(659.25, 783.99, 987.77, 1318.51, 1567.98)
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $mix = 0.0
    for ($n = 0; $n -lt $badgeNotes.Length; $n++) {
        $startTime = $n * 0.06
        if ($t -ge $startTime) {
            $noteT = $t - $startTime
            $noteEnv = [Math]::Exp(-$noteT * 5.0)
            $f = $badgeNotes[$n]
            $tone = [Math]::Sin(2 * [Math]::PI * $f * $noteT) * 0.5 + [Math]::Sin(2 * [Math]::PI * ($f * 2) * $noteT) * 0.3 + [Math]::Sin(2 * [Math]::PI * ($f * 3) * $noteT) * 0.15
            $mix += $tone * $noteEnv
        }
    }
    $samples[$i] = Clamp-Sample ($mix * 16000)
}
Create-Wav "sounds/badge.wav" $samples

# 7. GAME OVER (Melodic mellow descending chime)
$dur = 1.1
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
$goNotes = @(440.0, 392.0, 349.23, 293.66) # A4 -> G4 -> F4 -> D4
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $mix = 0.0
    for ($n = 0; $n -lt $goNotes.Length; $n++) {
        $startTime = $n * 0.18
        if ($t -ge $startTime) {
            $noteT = $t - $startTime
            $noteEnv = [Math]::Exp(-$noteT * 4.5)
            $f = $goNotes[$n]
            $tone = [Math]::Sin(2 * [Math]::PI * $f * $noteT) * 0.6 + [Math]::Sin(2 * [Math]::PI * ($f * 1.5) * $noteT) * 0.2
            $mix += $tone * $noteEnv
        }
    }
    $samples[$i] = Clamp-Sample ($mix * 18000)
}
Create-Wav "sounds/game_over.wav" $samples

# 8. INVALID / CANT PLACE (Rubbery soft boing)
$dur = 0.15
$count = [int]($dur * $sampleRate)
$samples = New-Object double[] $count
for ($i = 0; $i -lt $count; $i++) {
    $t = $i / $sampleRate
    $env = [Math]::Exp(-$t * 30)
    $freq = 180 + [Math]::Sin(2 * [Math]::PI * 40 * $t) * 40
    $val = [Math]::Sin(2 * [Math]::PI * $freq * $t) * 0.7
    $samples[$i] = Clamp-Sample ($val * $env * 24000)
}
Create-Wav "sounds/invalid.wav" $samples

Write-Host "Audio generation finished successfully!"
