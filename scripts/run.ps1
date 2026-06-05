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

$DefaultPiUsername = if ($env:PI_USERNAME) { $env:PI_USERNAME } else { "pi" }
$PiUsernameInput = Read-Host "Pi SSH username [$DefaultPiUsername]"
$PiUsername = if ([string]::IsNullOrWhiteSpace($PiUsernameInput)) { $DefaultPiUsername } else { $PiUsernameInput }

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

# Electric Forest turnkey automations --------------------------------------------
# Camp picker: pick a known Electric Forest camp/area or type your own. The
# selection is baked into the seeded auto-ack / sunrise messages at deploy time.
$EfCamps = @(
    "GA Campgrounds",
    "Good Life Village",
    "Camp Higher Love",
    "Maplewoods",
    "Lucky Lake",
    "The Back 40"
)
$EfCampDefault = if ($env:EF_CAMP) { $env:EF_CAMP } else { "" }
Write-Host ""
Write-Host "Which Electric Forest camp / area is this node at?"
for ($i = 0; $i -lt $EfCamps.Count; $i++) {
    Write-Host ("  {0}) {1}" -f ($i + 1), $EfCamps[$i])
}
$OtherIndex = $EfCamps.Count + 1
Write-Host ("  {0}) Other (type your own, e.g. ""GA Loop 5 by the showers"")" -f $OtherIndex)

if (-not [string]::IsNullOrWhiteSpace($EfCampDefault)) {
    $EfCampChoice = Read-Host "Camp [$EfCampDefault]"
} else {
    $EfCampChoice = Read-Host "Camp (1-$OtherIndex)"
}

if ([string]::IsNullOrWhiteSpace($EfCampChoice) -and -not [string]::IsNullOrWhiteSpace($EfCampDefault)) {
    $EfCamp = $EfCampDefault
} elseif ($EfCampChoice -eq "$OtherIndex") {
    $EfCamp = Read-Host "Enter your camp / location"
} elseif (($EfCampChoice -match '^\d+$') -and ([int]$EfCampChoice -ge 1) -and ([int]$EfCampChoice -le $EfCamps.Count)) {
    $EfCamp = $EfCamps[[int]$EfCampChoice - 1]
} else {
    # Treat any free-text entry as a custom camp name.
    $EfCamp = $EfCampChoice
}

while ([string]::IsNullOrWhiteSpace($EfCamp)) {
    $EfCamp = Read-Host "Camp / location cannot be empty. Enter your camp"
}
Write-Host "Camp set to: $EfCamp"

# MeshMonitor admin password (required by the seeder). Silent input.
while ($true) {
    $AdminPasswordSecure = Read-Host "MeshMonitor admin password to set (required, not 'changeme')" -AsSecureString
    $MeshmonitorAdminPassword = Convert-SecureStringToPlainText -SecureString $AdminPasswordSecure
    if ([string]::IsNullOrWhiteSpace($MeshmonitorAdminPassword)) {
        Write-Host "Admin password cannot be empty."
    } elseif ($MeshmonitorAdminPassword -eq "changeme") {
        Write-Host "Admin password must not be the default 'changeme'."
    } elseif ($MeshmonitorAdminPassword.Length -lt 8) {
        Write-Host "Admin password must be at least 8 characters (MeshMonitor requirement)."
    } else {
        break
    }
}

# Sunrise morning message (optional; default substitutes the camp).
$EfMorningDefault = if ($env:EF_MORNING_MESSAGE) { $env:EF_MORNING_MESSAGE } else { "$([char]::ConvertFromUtf32(0x1F305)) Good Morning from $EfCamp! $([char]0x2600)$([char]0xFE0F)$([char]::ConvertFromUtf32(0x1F332))" }
$EfMorningInput = Read-Host "Sunrise morning message [$EfMorningDefault]"
$EfMorningMessage = if ([string]::IsNullOrWhiteSpace($EfMorningInput)) { $EfMorningDefault } else { $EfMorningInput }

$ForceSeed = if ($env:FORCE_SEED) { $env:FORCE_SEED } else { "false" }

$DeployerImageName = if ($env:DEPLOYER_IMAGE_NAME) { $env:DEPLOYER_IMAGE_NAME } else { "meshmonitor-deployer:latest" }
# $PiUsername is set from the interactive prompt above.
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
    -e EF_CAMP=$EfCamp `
    -e EF_MORNING_MESSAGE=$EfMorningMessage `
    -e MESHMONITOR_ADMIN_PASSWORD=$MeshmonitorAdminPassword `
    -e FORCE_SEED=$ForceSeed `
    -e MESHMONITOR_IMAGE=$MeshmonitorImage `
    -e MESHMONITOR_HTTP_PORT=$MeshmonitorHttpPort `
    -e MESHTASTIC_BLE_BRIDGE_IMAGE=$MeshtasticBleBridgeImage `
    -e MESHTASTIC_BLE_BRIDGE_PORT=$MeshtasticBleBridgePort `
    $DeployerImageName

exit $LASTEXITCODE
