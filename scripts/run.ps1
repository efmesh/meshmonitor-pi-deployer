param()

function Convert-SecureStringToPlainText {
    param([Parameter(Mandatory = $true)][System.Security.SecureString]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Resolve-Path (Join-Path $ScriptDir "..")
$EnvFile = Join-Path $ProjectDir ".env"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^[ ]*#') { return }
        if ($_ -match '^[ ]*$') { return }
        $line = ($_ -split '\s+#', 2)[0].Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
}

$DefaultTargetPiIp = if ($env:TARGET_PI_IP) { $env:TARGET_PI_IP } else { "" }
if ([string]::IsNullOrWhiteSpace($DefaultTargetPiIp)) {
    $TargetPiIp = Read-Host "Pi IP address"
} else {
    $TargetPiIpInput = Read-Host "Pi IP address [$DefaultTargetPiIp]"
    if ([string]::IsNullOrWhiteSpace($TargetPiIpInput)) {
        $TargetPiIp = $DefaultTargetPiIp
    } else {
        $TargetPiIp = $TargetPiIpInput
    }
}

$DefaultTargetPiPassword = if ($env:TARGET_PI_PASSWORD) { $env:TARGET_PI_PASSWORD } else { "" }
if ([string]::IsNullOrWhiteSpace($DefaultTargetPiPassword)) {
    $TargetPiPasswordSecure = Read-Host "Pi password" -AsSecureString
    $TargetPiPassword = Convert-SecureStringToPlainText -SecureString $TargetPiPasswordSecure
} else {
    $TargetPiPasswordInput = Read-Host "Pi password [press Enter to use TARGET_PI_PASSWORD from .env]" -AsSecureString
    $TargetPiPasswordText = Convert-SecureStringToPlainText -SecureString $TargetPiPasswordInput
    if ([string]::IsNullOrWhiteSpace($TargetPiPasswordText)) {
        $TargetPiPassword = $DefaultTargetPiPassword
    } else {
        $TargetPiPassword = $TargetPiPasswordText
    }
}
$DefaultRadioConnectionType = if ($env:RADIO_CONNECTION_TYPE) { $env:RADIO_CONNECTION_TYPE } else { "wifi" }
$RadioConnectionType = Read-Host "MeshMonitor radio connection (wifi/bluetooth) [$DefaultRadioConnectionType]"
if ([string]::IsNullOrWhiteSpace($RadioConnectionType)) {
    $RadioConnectionType = $DefaultRadioConnectionType
}
$RadioConnectionType = $RadioConnectionType.ToLower()

$RadioIp = if ($env:RADIO_IP) { $env:RADIO_IP } else { "" }
if ($RadioConnectionType -eq "wifi") {
    $RadioIpInput = Read-Host "LoRa radio IP address"
    if (-not [string]::IsNullOrWhiteSpace($RadioIpInput)) {
        $RadioIp = $RadioIpInput
    }
}

$RadioMac = if ($env:RADIO_MAC) { $env:RADIO_MAC } else { "" }
if ($RadioConnectionType -eq "bluetooth") {
    $RadioMacInput = Read-Host "LoRa radio MAC (AA:BB:CC:DD:EE:FF)"
    if (-not [string]::IsNullOrWhiteSpace($RadioMacInput)) {
        $RadioMac = $RadioMacInput
    }
}

$DeployerImageName = if ($env:DEPLOYER_IMAGE_NAME) { $env:DEPLOYER_IMAGE_NAME } else { "meshmonitor-deployer:latest" }
$PiUsername = if ($env:PI_USERNAME) { $env:PI_USERNAME } else { "pi" }
$PiSshPort = if ($env:PI_SSH_PORT) { $env:PI_SSH_PORT } else { "22" }
$MeshmonitorImage = if ($env:MESHMONITOR_IMAGE) { $env:MESHMONITOR_IMAGE } else { "ghcr.io/yeraze/meshmonitor:latest" }
$MeshmonitorHttpPort = if ($env:MESHMONITOR_HTTP_PORT) { $env:MESHMONITOR_HTTP_PORT } else { "8080" }
$MeshtasticBleBridgeImage = if ($env:MESHTASTIC_BLE_BRIDGE_IMAGE) { $env:MESHTASTIC_BLE_BRIDGE_IMAGE } else { "ghcr.io/meshtastic/meshtastic-ble-bridge:latest" }
$MeshtasticBleBridgePort = if ($env:MESHTASTIC_BLE_BRIDGE_PORT) { $env:MESHTASTIC_BLE_BRIDGE_PORT } else { "4403" }

docker build -t $DeployerImageName $ProjectDir
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

docker run --rm `
    -e TARGET_PI_IP=$TargetPiIp `
    -e TARGET_PI_PASSWORD=$TargetPiPassword `
    -e RADIO_CONNECTION_TYPE=$RadioConnectionType `
    -e RADIO_IP=$RadioIp `
    -e RADIO_MAC=$RadioMac `
    -e PI_USERNAME=$PiUsername `
    -e PI_SSH_PORT=$PiSshPort `
    -e MESHMONITOR_IMAGE=$MeshmonitorImage `
    -e MESHMONITOR_HTTP_PORT=$MeshmonitorHttpPort `
    -e MESHTASTIC_BLE_BRIDGE_IMAGE=$MeshtasticBleBridgeImage `
    -e MESHTASTIC_BLE_BRIDGE_PORT=$MeshtasticBleBridgePort `
    $DeployerImageName

exit $LASTEXITCODE
