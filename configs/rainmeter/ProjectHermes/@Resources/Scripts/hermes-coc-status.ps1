if (Test-Connection hermes-remote-host -Count 1 -Quiet -ErrorAction SilentlyContinue) {
    "Online"
} else {
    "Offline"
}

