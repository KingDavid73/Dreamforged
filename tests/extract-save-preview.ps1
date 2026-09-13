param([Parameter(Mandatory=$true)][string]$SavePath,
      [Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$stream = [System.IO.File]::OpenRead($SavePath)
$reader = [System.IO.BinaryReader]::new($stream)
try {
    while ($stream.Position -lt $stream.Length) {
        $record = [System.Text.Encoding]::ASCII.GetString($reader.ReadBytes(4))
        $length = $reader.ReadUInt32()
        $null = $reader.ReadBytes(8)
        $recordEnd = $stream.Position + $length
        if ($record -eq 'SAVE') {
            while ($stream.Position -lt $recordEnd) {
                $name = [System.Text.Encoding]::ASCII.GetString($reader.ReadBytes(4))
                $size = $reader.ReadUInt32()
                if ($name -eq 'SCRN') {
                    $bytes = $reader.ReadBytes($size)
                    [System.IO.File]::WriteAllBytes($OutputPath, $bytes)
                    Write-Output "Extracted embedded screenshot: $OutputPath ($size bytes)"
                    return
                }
                $stream.Position += $size
            }
        }
        $stream.Position = $recordEnd
    }
    throw 'No SCRN image found in save.'
} finally { $reader.Dispose(); $stream.Dispose() }
