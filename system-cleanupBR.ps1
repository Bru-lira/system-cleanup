Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ============================================
# FUNCOES DE LIMPEZA
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
            # user_name = e-mail da conta Google logada no perfil (quando existe)
            $email = $p.Value.user_name
            if ([string]::IsNullOrWhiteSpace($email)) {
                $nomeLocal = if ($p.Value.name) { $p.Value.name } else { $p.Name }
                $display = "$nomeLocal (sem conta vinculada)"
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
            $profiles += [PSCustomObject]@{ Display = "Default (sem conta vinculada)"; Path = $def; Folder = "Default" }
        }
    }
    return $profiles
}

# ============================================
# HELPERS DE UI
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
# FORMULARIO PRINCIPAL
# ============================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "Limpeza do Sistema"
$form.Size = [System.Drawing.Size]::new(500, 560)
$form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false; $form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)

# ---- SECAO SISTEMA ----
$grpSys = New-GroupBox "Sistema" 15 15 460 150

$chkRecycleBin  = New-Ctrl System.Windows.Forms.CheckBox $grpSys @{Text="Esvaziar lixeira"; Location=[System.Drawing.Point]::new(15,35); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$chkTempFiles   = New-Ctrl System.Windows.Forms.CheckBox $grpSys @{Text="Limpar arquivos temporarios"; Location=[System.Drawing.Point]::new(15,65); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$lblSystemStatus= New-Ctrl System.Windows.Forms.Label   $grpSys @{Location=[System.Drawing.Point]::new(230,35); Size=[System.Drawing.Size]::new(210,55); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::Gray}
$btnSystem      = New-Ctrl System.Windows.Forms.Button  $grpSys @{Text="Executar Sistema"; Location=[System.Drawing.Point]::new(15,105); Size=[System.Drawing.Size]::new(425,30); BackColor=$colorBlue; ForeColor=[System.Drawing.Color]::White; FlatStyle="Flat"; Font=$fontBold9}

# ---- SECAO NAVEGADOR ----
$grpBrowser = New-GroupBox "Navegador" 15 180 460 220

New-Ctrl System.Windows.Forms.Label $grpBrowser @{Text="Chrome"; Location=[System.Drawing.Point]::new(15,30); Size=[System.Drawing.Size]::new(100,25); Font=$fontBold10} | Out-Null
$cmbProfiles    = New-Ctrl System.Windows.Forms.ComboBox $grpBrowser @{Location=[System.Drawing.Point]::new(15,58);  Size=[System.Drawing.Size]::new(300,25); DropDownStyle="DropDownList"; Font=$fontNorm9}
$lblProfileInfo = New-Ctrl System.Windows.Forms.Label   $grpBrowser @{Location=[System.Drawing.Point]::new(15,88);  Size=[System.Drawing.Size]::new(300,20); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::DarkGray}
$chkCache       = New-Ctrl System.Windows.Forms.CheckBox $grpBrowser @{Text="Limpar cache do navegador"; Location=[System.Drawing.Point]::new(15,115); Size=[System.Drawing.Size]::new(200,25); Font=$fontNorm9}
$lblCacheStatus = New-Ctrl System.Windows.Forms.Label   $grpBrowser @{Location=[System.Drawing.Point]::new(230,115); Size=[System.Drawing.Size]::new(210,25); Font=$fontNorm8; ForeColor=[System.Drawing.Color]::Gray}
$btnBrowser     = New-Ctrl System.Windows.Forms.Button  $grpBrowser @{Text="Executar Navegador"; Location=[System.Drawing.Point]::new(15,160); Size=[System.Drawing.Size]::new(425,30); BackColor=$colorBlue; ForeColor=[System.Drawing.Color]::White; FlatStyle="Flat"; Font=$fontBold9}

# ---- BOTAO FECHAR ----
$btnClose = New-Ctrl System.Windows.Forms.Button $form @{Text="Fechar"; Location=[System.Drawing.Point]::new(395,415); Size=[System.Drawing.Size]::new(80,30); BackColor=[System.Drawing.Color]::LightGray; FlatStyle="Flat"}

# ---- POPULAR PERFIS ----
$profilesList = Get-ChromeProfiles
$profilesList | ForEach-Object { $cmbProfiles.Items.Add($_.Display) | Out-Null }
if ($cmbProfiles.Items.Count -gt 0) {
    $cmbProfiles.SelectedIndex = 0
    $lblProfileInfo.Text = "Conta: $($profilesList[0].Display)"
}
$cmbProfiles.Add_SelectedIndexChanged({
    if ($cmbProfiles.SelectedIndex -ge 0) {
        $lblProfileInfo.Text = "Conta: $($profilesList[$cmbProfiles.SelectedIndex].Display)"
    }
})

# ============================================
# EVENTOS
# ============================================

$btnSystem.Add_Click({
    $tasks = @(
        @{ Chk=$chkRecycleBin.Checked; Status="Esvaziando lixeira...";           Fn={ Clear-RecycleBin-Safe }; OkMsg="Lixeira esvaziada com sucesso";        ErrMsg="Falha ao esvaziar a lixeira";          Label="Lixeira"     },
        @{ Chk=$chkTempFiles.Checked;  Status="Limpando arquivos temporarios..."; Fn={ Clear-TempFiles };       OkMsg="Arquivos temporarios removidos";       ErrMsg="Falha ao limpar arquivos temporarios"; Label="Temporarios" }
    )

    $linhas = @(); $concluido = @()

    foreach ($t in $tasks) {
        if (-not $t.Chk) { continue }
        $lblSystemStatus.Text = $t.Status
        $lblSystemStatus.ForeColor = [System.Drawing.Color]::Orange
        $form.Refresh()

        if (& $t.Fn) {
            $linhas += "[OK] $($t.OkMsg)"
            $concluido += $t.Label
        } else {
            $linhas += "[ERRO] $($t.ErrMsg)"
        }
    }

    if ($linhas.Count -eq 0) {
        $lblSystemStatus.Text = "Nenhuma tarefa selecionada"; $lblSystemStatus.ForeColor = [System.Drawing.Color]::Gray
        [System.Windows.Forms.MessageBox]::Show("Selecione pelo menos uma tarefa!", "Aviso")
    } else {
        $lblSystemStatus.Text      = if ($concluido.Count -gt 0) { "Concluido: $($concluido -join ', ')" } else { "Falha na execucao" }
        $lblSystemStatus.ForeColor = [System.Drawing.Color]::Green

        $resultMsg = "Resultado da limpeza:`n`n" + ($linhas -join "`n")
        [System.Windows.Forms.MessageBox]::Show($resultMsg, "Limpeza do Sistema")
    }
})

$btnBrowser.Add_Click({
    if (-not $chkCache.Checked) { [System.Windows.Forms.MessageBox]::Show("Nenhuma tarefa selecionada para o navegador!", "Aviso"); return }
    if ($cmbProfiles.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Nenhum perfil encontrado ou selecionado!", "Erro"); return }

    $sel = $profilesList[$cmbProfiles.SelectedIndex]
    $lblCacheStatus.Text = "Limpando cache..."; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Orange
    $form.Refresh()

    if (Clear-ChromeCache -ProfilePath $sel.Path) {
        $lblCacheStatus.Text = "[OK] Cache limpo"; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Green
        $msg = "[OK] Cache do perfil limpo com sucesso`n`n$($sel.Display)`n`nHistorico e senhas foram preservados."
        [System.Windows.Forms.MessageBox]::Show($msg, "Concluido")
    } else {
        $lblCacheStatus.Text = "[ERRO] Falha ao limpar cache"; $lblCacheStatus.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("[ERRO] Falha ao limpar o cache do perfil selecionado.", "Erro")
    }
})

$btnClose.Add_Click({ $form.Close() })

$form.ShowDialog() | Out-Null
