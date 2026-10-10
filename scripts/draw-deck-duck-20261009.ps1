# Draws Deck Duck's nine mood frames (256x256, transparent) and a 3x3 sheet on grey.
# Hand-drawn stand-in until generated art lands. Run: powershell -File scripts\draw-deck-duck-20261009.ps1
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$frames = Join-Path $root 'art\frames'; $sheets = Join-Path $root 'art\sheets'
New-Item -ItemType Directory -Force $frames, $sheets | Out-Null

function C($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
$body = C '#FF2BD6'; $beak = C '#B6FF00'; $deck = C '#1A1A2E'; $key = C '#00F0FF'
$eye = C '#000000'; $hi = C '#FFFFFF'; $blush = C '#FFB3E6'; $out = C '#000000'
$N = 64; $moods = 'neutral','blink','happy','curious','worried','sad','unwell','shocked','sleeping'

function Px($g, $c, $x, $y, $w = 1, $h = 1) { $g.FillRectangle((New-Object System.Drawing.SolidBrush $c), $x, $y, $w, $h) }

function Draw($mood) {
  $bmp = New-Object System.Drawing.Bitmap $N, $N
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'None'; $g.Clear([System.Drawing.Color]::Transparent)
  $b = New-Object System.Drawing.SolidBrush $body
  $g.FillEllipse($b, 13, 27, 38, 29)        # body
  $g.FillEllipse($b, 19, 7, 26, 26)         # head
  Px $g $beak 24 55 5 3; Px $g $beak 36 55 5 3   # feet
  # Stream Deck wing: dark panel with 3x2 cyan keys
  Px $g $deck 21 36 20 14
  foreach ($r in 0, 1) { foreach ($k in 0, 1, 2) { Px $g $key (23 + $k * 6) (38 + $r * 6) 4 4 } }
  # beak (open for happy/shocked)
  Px $g $beak 42 19 9 4
  if ($mood -eq 'happy') { Px $g $beak 42 24 7 2; Px $g $eye 43 23 6 1 }
  elseif ($mood -eq 'shocked') { Px $g $beak 42 25 8 3; Px $g $eye 43 23 6 2 }
  else { Px $g $beak 42 23 7 2 }
  Px $g $blush 24 24 3 2; Px $g $blush 38 24 3 2
  $L = 27; $R = 36; $y = 15
  switch ($mood) {
    'blink'    { Px $g $eye $L 17 3 1; Px $g $eye $R 17 3 1 }
    'sleeping' { foreach ($x in $L, $R) { Px $g $eye $x 18 1 1; Px $g $eye ($x + 1) 19 1 1; Px $g $eye ($x + 2) 18 1 1 } }
    'happy'    { foreach ($x in $L, $R) { Px $g $eye $x 17 1 1; Px $g $eye ($x + 1) 16 1 1; Px $g $eye ($x + 2) 17 1 1 } }
    'shocked'  { foreach ($x in $L, $R) { Px $g $eye $x 14 3 3; Px $g $hi $x 14 1 1 } }
    'unwell'   { foreach ($x in $L, $R) { Px $g $eye $x 17 2 1; Px $g $eye $x 16 2 1 }; Px $g (C '#B000A0') ($L - 1) 15 4 1; Px $g (C '#B000A0') ($R - 1) 15 4 1 }
    default    { foreach ($x in $L, $R) { Px $g $eye $x $y 2 2; Px $g $hi $x $y 1 1 } }
  }
  switch ($mood) {
    'curious' { Px $g $eye $L 12 3 1; Px $g $eye $R 12 3 1 }
    'worried' { Px $g $eye ($L - 1) 13 2 1; Px $g $eye ($L + 1) 12 2 1; Px $g $eye $R 12 2 1; Px $g $eye ($R + 2) 13 2 1 }
    'sad'     { Px $g $eye ($L - 1) 12 2 1; Px $g $eye ($L + 1) 13 2 1; Px $g $eye $R 13 2 1; Px $g $eye ($R + 2) 12 2 1 }
  }
  $g.Dispose()
  # one-pixel black outline around the silhouette
  $o = New-Object System.Drawing.Bitmap $N, $N
  for ($x = 0; $x -lt $N; $x++) { for ($yy = 0; $yy -lt $N; $yy++) {
    $p = $bmp.GetPixel($x, $yy)
    if ($p.A -gt 0) { $o.SetPixel($x, $yy, $p); continue }
    foreach ($d in @(@(1,0),@(-1,0),@(0,1),@(0,-1))) {
      $nx = $x + $d[0]; $ny = $yy + $d[1]
      if ($nx -ge 0 -and $ny -ge 0 -and $nx -lt $N -and $ny -lt $N -and $bmp.GetPixel($nx, $ny).A -gt 0) { $o.SetPixel($x, $yy, $out); break }
    }
  } }
  $bmp.Dispose()
  $big = New-Object System.Drawing.Bitmap 256, 256
  $g2 = [System.Drawing.Graphics]::FromImage($big)
  $g2.InterpolationMode = 'NearestNeighbor'; $g2.PixelOffsetMode = 'Half'
  $g2.DrawImage($o, 0, 0, 256, 256); $g2.Dispose(); $o.Dispose()
  return $big
}

$sheet = New-Object System.Drawing.Bitmap 768, 768
$gs = [System.Drawing.Graphics]::FromImage($sheet); $gs.Clear((C '#808080'))
for ($i = 0; $i -lt 9; $i++) {
  $f = Draw $moods[$i]
  $f.Save((Join-Path $frames "$($moods[$i]).png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $gs.DrawImage($f, ($i % 3) * 256, [math]::Floor($i / 3) * 256, 256, 256); $f.Dispose()
}
$gs.Dispose(); $sheet.Save((Join-Path $sheets 'deck-duck.png'), [System.Drawing.Imaging.ImageFormat]::Png); $sheet.Dispose()
Write-Output "Drew $($moods.Count) frames and the sheet."
