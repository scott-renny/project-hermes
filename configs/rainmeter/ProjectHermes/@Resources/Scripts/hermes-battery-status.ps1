Add-Type -AssemblyName System.Windows.Forms
$p = [System.Windows.Forms.SystemInformation]::PowerStatus
$percent = [math]::Round($p.BatteryLifePercent * 100)

switch ($p.PowerLineStatus.ToString()) {
    "Online"  { "$percent%  AC" }
    "Offline" { "$percent%  Battery" }
    default   { "$percent%" }
}
