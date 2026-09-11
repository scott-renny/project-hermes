$ssid = netsh wlan show interfaces | Select-String '^\s*SSID\s*:' | Select-Object -First 1
if ($ssid) {
    (($ssid -split ':',2)[1]).Trim()
} else {
    "Disconnected"
}
