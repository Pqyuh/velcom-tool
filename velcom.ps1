# Velcom Gaming Tool - Private Edition
# Developed and Owned by Velcom (Private)
# Version: 1.0

$CurrentVersion = "1.1"
$UpdateUrl = "https://raw.githubusercontent.com/Pqyuh/velcom-tool/refs/heads/main/velcom.ps1" # استبدل هذا بالرابط الخام لملفك على GitHub

## Configure this
$Host.UI.RawUI.WindowTitle = "VELCOM PRIVATE INSTALLER V$CurrentVersion"
$name = "velcom" # automatic first letter uppercase included
$link = "https://relaxed-cobbler-d255eb.netlify.app/ltsteamplugin.zip"
$milleniumTimer = 5 # in seconds for auto-installation

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

function Update-Velcom {
    try {
        $RemoteContent = (Invoke-WebRequest -Uri $UpdateUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue).Content
        if ($RemoteContent -match '# Version: (\d+\.\d+)') {
            $RemoteVersion = $matches[1]
            if ([float]$RemoteVersion -gt [float]$CurrentVersion) {
                $MyPath = $MyInvocation.MyCommand.Path
                if ($null -ne $MyPath -and (Test-Path $MyPath)) {
                    Write-Host "`n[!] New update found ($RemoteVersion). Downloading..." -ForegroundColor Yellow
                    Invoke-WebRequest -Uri $UpdateUrl -OutFile "$MyPath.new"
                    Move-Item -Path "$MyPath.new" -Destination $MyPath -Force
                    Write-Host "[+] Update successful! Please restart the script.`n" -ForegroundColor Green
                    pause
                    exit
                }
            }
        }
    }
    catch {
        # الصمت في حالة فشل الاتصال أو الرابط غير الصحيح
    }
}

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Log "ERR" "ACCESS DENIED: Required Administrator privileges."
    Log "INFO" "Please run as Admin to verify ownership."
    pause
    exit
}

# Hidden defines
$steam = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam").InstallPath

#### Logging defines ####
function Log {
    param ([string]$Type, [string]$Message, [boolean]$NoNewline = $false)

    $Type = $Type.ToUpper()
    switch ($Type) {
        "OK" { $foreground = "Green" }
        "INFO" { $foreground = "Cyan" }
        "ERR" { $foreground = "Red" }
        "WARN" { $foreground = "Yellow" }
        "LOG" { $foreground = "Magenta" }
        "AUX" { $foreground = "DarkGray" }
        default { $foreground = "White" }
    }

    $date = Get-Date -Format "HH:mm:ss"
    $prefix = if ($NoNewline) { "`r[$date] " } else { "[$date] " }
    Write-Host $prefix -ForegroundColor "Cyan" -NoNewline

    Write-Host [$Type] $Message -ForegroundColor $foreground -NoNewline:$NoNewline
}
Log "OK" "=========================================="
Log "OK" "          VELCOM PRIVATE TOOL             "
Log "OK" "     OWNED & DEVELOPED BY VELCOM          "
Log "OK" "=========================================="
Log "INFO" "Authenticated: Velcom Private System"
Log "AUX" "Property of Velcom"
Update-Velcom
Write-Host

# To hide IEX blue box thing
$ProgressPreference = 'SilentlyContinue'



Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force


#### Requirements part ####

# Steamtools check
# TODO: Make this prettier?
$path = Join-Path $steam "xinput1_4.dll"
if ( Test-Path $path ) {
    Log "INFO" "Velcom core already initialized"
}
else {
    # Filtering the installation script
    $script = Invoke-RestMethod "https://steam.run"
    $keptLines = @()

    foreach ($line in $script -split "`n") {
        $conditions = @( # Removes lines containing one of those
            ($line -imatch "Start-Process" -and $line -imatch "steam"),
            ($line -imatch "steam\.exe"),
            ($line -imatch "Start-Sleep" -or $line -imatch "Write-Host"),
            ($line -imatch "cls" -or $line -imatch "exit"),
            ($line -imatch "Stop-Process" -and -not ($line -imatch "Get-Process"))
        )
        
        if (-not($conditions -contains $true)) {
            $keptLines += $line
        }
    }

    $SteamtoolsScript = $keptLines -join "`n"
    Log "ERR" "Core component 1 not found."
    
    # Retrying with a max of 5
    for ($i = 0; $i -lt 5; $i++) {

        Log "AUX" "Install it at your own risk! Close this script if you don't want to."
        Log "WARN" "Pressing any key will install steamtools (UI-less)."
        
        [void][System.Console]::ReadKey($true)
        Write-Host
        Log "WARN" "Installing Velcom Core 1"
        
        Invoke-Expression $SteamtoolsScript *> $null

        if ( Test-Path $path ) {
            Log "OK" "Velcom Core 1 initialized"
            break
        }
        else {
            Log "ERR" "Steamtools installation failed, retrying..."
        }

    }
}

# Millenium check
$milleniumInstalling = $false
foreach ($file in @("millennium.dll", "python311.dll")) {
    if (!( Test-Path (Join-Path $steam $file) )) {
        
        # Ask confirmation to download
        Log "ERR" "Velcom Core 2 not found, setup will start in 5 seconds."
        Log "WARN" "Press any key to cancel the installation."
        
        for ($i = $milleniumTimer; $i -ge 0; $i--) {
            # Wheter a key was pressed
            if ([Console]::KeyAvailable) {
                Write-Host
                Log "ERR" "Installation cancelled by user."
                exit
            }

            Log "LOG" "Installing Millenium in $i second(s)... Press any key to cancel." $true
            Start-Sleep -Seconds 1
        }
        Write-Host



        Log "INFO" "Installing Velcom Core 2"

        Invoke-Expression "& { $(Invoke-RestMethod 'https://clemdotla.github.io/millennium-installer-ps1/millennium.ps1') } -NoLog -DontStart -SteamPath '$steam'"

        Log "OK" "Velcom Core 2 finalized"
        $milleniumInstalling = $true
        break
    }
}
if ($milleniumInstalling -eq $false) { Log "INFO" "Velcom Core 2 already initialized" }



#### Plugin part ####
# Ensuring \Steam\plugins
if (!( Test-Path (Join-Path $steam "plugins") )) {
    New-Item -Path (Join-Path $steam "plugins") -ItemType Directory *> $null
}


$Path = Join-Path $steam "plugins\$name" # Defaulting if no install found

# Checking for plugin named "$name"
foreach ($plugin in Get-ChildItem -Path (Join-Path $steam "plugins") -Directory) {
    $testpath = Join-Path $plugin.FullName "plugin.json"
    if (Test-Path $testpath) {
        $json = Get-Content $testpath -Raw | ConvertFrom-Json
        if ($json.name -eq $name) {
            Log "INFO" "Plugin already installed, updating it"
            $Path = $plugin.FullName # Replacing default path
            break
        }
    }
}

# Installation 
$subPath = Join-Path $env:TEMP "$name.zip"

Log "LOG" "give me the game"
Invoke-WebRequest -Uri $link -OutFile $subPath *> $null
if ( !( Test-Path $subPath ) ) {
    Log "ERR" "Failed to download $name"
    exit
}
Log "LOG" "Unzipping $name"
# DM clem.la on Discord if you have a way to remove the blue progression bar in the console
Expand-Archive -Path $subPath -DestinationPath $Path *>$null
if ( Test-Path $subPath ) {
    Remove-Item $subPath -ErrorAction SilentlyContinue
}

Log "OK" "Velcom tool ready!"


# Removing beta
$betaPath = Join-Path $steam "package\beta"
if ( Test-Path $betaPath ) {
    Remove-Item $betaPath -Recurse -Force
}
# Removing potential x32 (kinda greedy but ppl got issues and was hard to fix without knowing it was the issue, ppl don't know what they run)
$cfgPath = Join-Path $steam "steam.cfg"
if ( Test-Path $cfgPath ) {
    Remove-Item $cfgPath -Recurse -Force
}
Remove-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam" -Name "SteamCmdForceX86" -ErrorAction SilentlyContinue


# Toggling the plugin on (+turning off updateChecking to try fixing a bug where steam doesn't start)
$configPath = Join-Path $steam "ext/config.json"
if (-not (Test-Path $configPath)) {
    $config = @{
        plugins = @{
            enabledPlugins = @($name)
        }
        general = @{
            checkForMillenniumUpdates = $false
        }
    }
    New-Item -Path (Split-Path $configPath) -ItemType Directory -Force | Out-Null
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}
else {
    $config = (Get-Content $configPath -Raw -Encoding UTF8) | ConvertFrom-Json

    function _EnsureProperty {
        param($Object, $PropertyName, $DefaultValue)
        if (-not $Object.$PropertyName) {
            $Object | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $DefaultValue -Force
        }
    }

    _EnsureProperty $config "general" @{}
    _EnsureProperty $config "general.checkForMillenniumUpdates" $false
    $config.general.checkForMillenniumUpdates = $false

    _EnsureProperty $config "plugins" @{ enabledPlugins = @() }
    _EnsureProperty $config "plugins.enabledPlugins" @()
    
    $pluginsList = @($config.plugins.enabledPlugins)
    if ($pluginsList -notcontains $name) {
        $pluginsList += $name
        $config.plugins.enabledPlugins = $pluginsList
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
}
Log "OK" "Plugin enabled"


# Result showing
Write-Host
if ($milleniumInstalling) { Log "WARN" "Velcom setup is completing, please wait..." }


# Start with the "-clearbeta" argument
$exe = Join-Path $steam "steam.exe"
Start-Process $exe -ArgumentList "-clearbeta"

Log "INFO" "Restarting game launcher..."
Log "WARN" "Optimization in progress, please do not close this window."
Log "OK" "Velcom is now active."
Log "AUX" "Powered by Velcom."

