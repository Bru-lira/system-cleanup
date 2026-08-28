Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ============================================
# CLEANUP FUNCTIONS
# ============================================

function Clear-RecycleBin-Safe {
    try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; return $true }
    catch { return $false }
}

function Clear-TempFiles {
    try {
        Remove-Item "$env:TEMP\*"          -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*"    -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    } catch { return $false }
}

function Clear-ChromeCache {
    param([string]$ProfilePath)
    try {
        Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        @("Cache\*","Code Cache\*","GPUCache\*","Old Storage\*",
          "Service Worker\CacheStorage\*","Service Worker\ScriptCache\*") | ForEach-Object {
            $p = Join-Path $ProfilePath $_
            if (Test-Path $p) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
        }
        return $true
    } catch { return $false }
}

function Get-ChromeProfiles {
    $udPath     = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    $statePath  = Join-Path $udPath "Local State"
    $profiles   = @()

    if (Test-Path $statePath) {
        $cache = (Get-Content -Raw $statePath | ConvertFrom-Json).profile.info_cache
        foreach ($p in $cache.PSObject.Properties) {
            # user_name = email of the Google account signed in to the profile (if any)
            $email = $p.Value.user_name
            if ([string]::IsNullOrWhiteSpace($email)) {
                $localName = if ($p.Value.name) { $p.Value.name } else { $p.Name }
                $display = "$localName (no linked account)"
            } else {
                $display = $email
            }

            $profiles += [PSCustomObject]@{
                Display = $display
                Path    = Join-Path $udPath $p.Name
                Folder  = $p.Name
            }
        }
    }

    if ($profiles.Count -eq 0) {
        $def = Join-Path $udPath "Default"
        if (Test-Path $def) {
            $profiles += [PSCustomObject]@{ Display = "Default (no linked account)"; Path = $def; Folder = "Default" }
        }
    }
    return $profiles
}

# ============================================
# UI HELPERS
# ============================================

$fontBold9  = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Bold)
$fontBold10 = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontNorm9  = New-Object System.Drawing.Font("Segoe UI", 9)
$fontNorm8  = New-Object System.Drawing.Font("Segoe UI", 8)
$colorBlue  = [System.Drawing.Color]::FromArgb(0, 120, 215)

function New-Ctrl {
    param($Type, $Parent, [hashtable]$Props)
    $ctrl = New-Object $Type
    foreach ($kv in $Props.GetEnumerator()) { $ctrl.$($kv.Key) = $kv.Value }
    $Parent.Controls.Add($ctrl)
    return $ctrl
}

function New-GroupBox($text, $x, $y, $w, $h) {
    $gb = New-Object System.Windows.Forms.GroupBox
    $gb.Text = $text; $gb.Location = [System.Drawing.Point]::new($x,$y)
    $gb.Size = [System.Drawing.Size]::new($w,$h); $gb.Font = $fontBold10
    $form.Controls.Add($gb); return $gb
}

# ============================================
# MAIN FORM
# ============================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "System Cleanup"
$form.Size = [System.Drawing.Size]::new(500, 560)
$form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false; $form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)

# ---- SYSTEM SECTION ----
$grpSys = New-GroupBox "System" 15 15 460 150

$chkRecycleBin  = New-Ctrl System.Windows.Forms.CheckBox $grpSys @{Text="Empty Recycle Bin"; Location=[System.Drawing.Point]::new(15,35); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$chkTempFiles   = New-Ctrl System.Windows.Forms.CheckBox $grpSys @{Text="Clear temporary files"; Location=[System.Drawing.Point]::new(15,65); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$lblSystemStatus= New-Ctrl System.Windows.Forms.Label   $grpSys @{Location=[System.Drawing.Point]::new(230,35); Size=[System.Drawing.Size]::new(210,55); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::Gray}
$btnSystem      = New-Ctrl System.Windows.Forms.Button  $grpSys @{Text="Run System Cleanup"; Location=[System.Drawing.Point]::new(15,105); Size=[System.Drawing.Size]::new(425,30); BackColor=$colorBlue; ForeColor=[System.Drawing.Color]::White; FlatStyle="Flat"; Font=$fontBold9}

# ---- BROWSER SECTION ----
$grpBrowser = New-GroupBox "Browser" 15 180 460 220

New-Ctrl System.Windows.Forms.Label $grpBrowser @{Text="Chrome"; Location=[System.Drawing.Point]::new(15,30); Size=[System.Drawing.Size]::new(100,25); Font=$fontBold10} | Out-Null
$cmbProfiles    = New-Ctrl System.Windows.Forms.ComboBox $grpBrowser @{Location=[System.Drawing.Point]::new(15,58);  Size=[System.Drawing.Size]::new(300,25); DropDownStyle="DropDownList"; Font=$fontNorm9}
$lblProfileInfo = New-Ctrl System.Windows.Forms.Label   $grpBrowser @{Location=[System.Drawing.Point]::new(15,88);  Size=[System.Drawing.Size]::new(300,20); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::DarkGray}
$chkCache       = New-Ctrl System.Windows.Forms.CheckBox $grpBrowser @{Text="Clear browser cache"; Location=[System.Drawing.Point]::new(15,115); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$lblCacheStatus = New-Ctrl System.Windows.Forms.Label   $grpBrowser @{Location=[System.Drawing.Point]::new(230,115); Size=[System.Drawing.Size]::new(210,25); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::Gray}
$btnBrowser     = New-Ctrl System.Windows.Forms.Button  $grpBrowser @{Text="Run Browser Cleanup"; Location=[System.Drawing.Point]::new(15,160); Size=[System.Drawing.Size]::new(425,30); BackColor=$colorBlue; ForeColor=[System.Drawing.Color]::White; FlatStyle="Flat"; Font=$fontBold9}

# ---- CLOSE BUTTON ----
$btnClose = New-Ctrl System.Windows.Forms.Button $form @{Text="Close"; Location=[System.Drawing.Point]::new(395,415); Size=[System.Drawing.Size]::new(80,30); BackColor=[System.Drawing.Color]::LightGray; FlatStyle="Flat"}

# ---- POPULATE PROFILES ----
$profilesList = Get-ChromeProfiles
$profilesList | ForEach-Object { $cmbProfiles.Items.Add($_.Display) | Out-Null }
if ($cmbProfiles.Items.Count -gt 0) {
    $cmbProfiles.SelectedIndex = 0
    $lblProfileInfo.Text = "Account: $($profilesList[0].Display)"
}
$cmbProfiles.Add_SelectedIndexChanged({
    if ($cmbProfiles.SelectedIndex -ge 0) {
        $lblProfileInfo.Text = "Account: $($profilesList[$cmbProfiles.SelectedIndex].Display)"
    }
})

# ============================================
# EVENTS
# ============================================

$btnSystem.Add_Click({
    $tasks = @(
        @{ Chk=$chkRecycleBin.Checked; Status="Emptying Recycle Bin...";        Fn={ Clear-RecycleBin-Safe }; OkMsg="Recycle Bin emptied successfully";     ErrMsg="Failed to empty the Recycle Bin";      Label="Recycle Bin"  },
        @{ Chk=$chkTempFiles.Checked;  Status="Clearing temporary files...";    Fn={ Clear-TempFiles };       OkMsg="Temporary files removed";              ErrMsg="Failed to clear temporary files";      Label="Temp Files"   }
    )

    $lines = @(); $completed = @()

    foreach ($t in $tasks) {
        if (-not $t.Chk) { continue }
        $lblSystemStatus.Text = $t.Status
        $lblSystemStatus.ForeColor = [System.Drawing.Color]::Orange
        $form.Refresh()

        if (& $t.Fn) {
            $lines += "[OK] $($t.OkMsg)"
            $completed += $t.Label
        } else {
            $lines += "[ERROR] $($t.ErrMsg)"
        }
    }

    if ($lines.Count -eq 0) {
        $lblSystemStatus.Text = "No task selected"; $lblSystemStatus.ForeColor = [System.Drawing.Color]::Gray
        [System.Windows.Forms.MessageBox]::Show("Select at least one task!", "Warning")
    } else {
        $lblSystemStatus.Text      = if ($completed.Count -gt 0) { "Completed: $($completed -join ', ')" } else { "Execution failed" }
        $lblSystemStatus.ForeColor = [System.Drawing.Color]::Green

        $resultMsg = "Cleanup result:`n`n" + ($lines -join "`n")
        [System.Windows.Forms.MessageBox]::Show($resultMsg, "System Cleanup")
    }
})

$btnBrowser.Add_Click({
    if (-not $chkCache.Checked) { [System.Windows.Forms.MessageBox]::Show("No task selected for the browser!", "Warning"); return }
    if ($cmbProfiles.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("No profile found or selected!", "Error"); return }

    $sel = $profilesList[$cmbProfiles.SelectedIndex]
    $lblCacheStatus.Text = "Clearing cache..."; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Orange
    $form.Refresh()

    if (Clear-ChromeCache -ProfilePath $sel.Path) {
        $lblCacheStatus.Text = "[OK] Cache cleared"; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Green
        $msg = "[OK] Profile cache cleared successfully`n`n$($sel.Display)`n`nHistory and passwords were preserved."
        [System.Windows.Forms.MessageBox]::Show($msg, "Completed")
    } else {
        $lblCacheStatus.Text = "[ERROR] Failed to clear cache"; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("[ERROR] Failed to clear the selected profile's cache.", "Error")
    }
})

$btnClose.Add_Click({ $form.Close() })

$form.ShowDialog() | Out-Null
