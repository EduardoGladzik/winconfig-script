# =================================================================
# Windows functions
# =================================================================

function Set-DisableUAC {
    Write-Host "Desativando o UAC..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Type DWord -Force
}

function Set-EnableRDP {
    Write-Host "Configurando Área de Trabalho Remota (RDP)..."
    Write-Host "  > Ativando conexões RDP..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Type DWord -Force

    Write-Host "  > Desativando exigência de NLA (Autenticação de Nível de Rede)..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0 -Type DWord -Force

    Write-Host "  > Abrindo portas no Firewall..."
    netsh advfirewall firewall set rule group="Ambiente de Trabalho Remoto" new enable=Yes | Out-Null
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes | Out-Null
    netsh advfirewall firewall add rule name="RDP-Manual-TCP-3389" dir=in action=allow protocol=TCP localport=3389 | Out-Null
}

function Set-BestPerformance {
    Write-Host "Configurando Visual: Personalizado..."

    $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    Set-ItemProperty -Path $explorerPath -Name "VisualFXSetting" -Value 3 -Type DWord -Force

    $mask = [byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)
    Set-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -Value $mask -Type Binary -Force

    Write-Host "  > Ativando conteúdo da gui ao arrastar..."
    Set-ItemProperty -Path $desktopPath -Name "DragFullWindows" -Value 1 -Type String -Force

    Write-Host "  > Ativando miniaturas..."
    Set-ItemProperty -Path $advancedPath -Name "IconsOnly" -Value 0 -Type DWord -Force

    Set-ItemProperty -Path $advancedPath -Name "ListviewShadow" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $advancedPath -Name "TaskbarAnimations" -Value 0 -Type DWord -Force

    Write-Host "  > Reiniciando Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Set-AdminUser($password) {
    Write-Host "Habilitando usuário 'Administrador'..."
    net user Administrator $password
    if ($LASTEXITCODE -ne 0) { 
        throw "Falha ao definir a senha. Verifique a complexidade. (Código: $LASTEXITCODE)"
    }
    net user Administrator /active:yes
    if ($LASTEXITCODE -ne 0) { 
        throw "Falha ao ATIVAR o usuário Administrador. (Código: $LASTEXITCODE)"
    }
}

function Set-AutoUpdates {
    Write-Host "Configurando Windows Update..."
    Write-Host "  > Registrando serviço 'Microsoft Update'..."
    try {
        $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
        $ServiceManager.ClientApplicationID = "PowerShellScript"
        $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "") | Out-Null
    } catch { Write-Host "    (Serviço já pode estar ativo)" }

    Write-Host "  > Ativando 'Inovação Contínua'..."
    $UXKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (!(Test-Path $UXKey)) { New-Item -Path $UXKey -Force | Out-Null }
    Set-ItemProperty -Path $UXKey -Name "IsContinuousInnovationOptedIn" -Value 1 -Type DWord -Force

    Write-Host "  > Iniciando serviços..."
    sc.exe config wuauserv start= auto; sc.exe start wuauserv 2>$null
    sc.exe config bits start= auto; sc.exe start bits 2>$null
    sc.exe config UsoSvc start= auto; sc.exe start UsoSvc 2>$null

    Write-Host "  > Limpando políticas restritivas..."
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue

    Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -ErrorAction SilentlyContinue
}

function Enable-TelnetAndSMB {
    Write-Host "Habilitando Cliente Telnet..."
    DISM /Online /Enable-Feature /FeatureName:TelnetClient /NoRestart | Out-Null
    
    Write-Host "Configurando SMB 1.0 (Apenas Cliente)..."
    DISM /Online /Enable-Feature /FeatureName:SMB1Protocol-Client /NoRestart | Out-Null
    DISM /Online /Disable-Feature /FeatureName:SMB1Protocol-Server /NoRestart | Out-Null
    DISM /Online /Disable-Feature /FeatureName:SMB1Protocol-Deprecation /NoRestart | Out-Null
}

function Set-NetworkSharing {
    Write-Host "Configurando Firewall para Compartilhamento..."
    $gruposFile = @("Compartilhamento de Arquivo e Impressora", "Partilha de Ficheiros e Impressoras", "File and Printer Sharing")
    $gruposDiscovery = @("Descoberta de Rede", "Deteção de Rede", "Network Discovery")

    foreach ($nome in $gruposFile) { netsh advfirewall firewall set rule group="$nome" new enable=Yes | Out-Null }
    foreach ($nome in $gruposDiscovery) { netsh advfirewall firewall set rule group="$nome" new enable=Yes | Out-Null }

    # Fallback
    netsh advfirewall firewall add rule name="SMB-Manual-TCP-445" dir=in action=allow protocol=TCP localport=445 | Out-Null
    netsh advfirewall firewall add rule name="NetBIOS-Manual-TCP-139" dir=in action=allow protocol=TCP localport=139 | Out-Null
    netsh advfirewall firewall add rule name="NetBIOS-Manual-UDP" dir=in action=allow protocol=UDP localport=137,138 | Out-Null
    netsh advfirewall firewall add rule name="ICMP-Ping-Manual" dir=in action=allow protocol=ICMPv4 | Out-Null
}

function Set-AdvancedSharing {
    Write-Host "Configurando Opções Avançadas (AMBOS ATIVADOS)..."
    Write-Host "  > Ativando compartilhamento da pasta Pública..."
    $publicPath = "$env:SystemDrive\Users\Public"
    icacls $publicPath /grant "Todos:(OI)(CI)F" /T /Q 2>$null
    icacls $publicPath /grant "Everyone:(OI)(CI)F" /T /Q 2>$null
    net share Public /delete 2>$null
    net share Public="$publicPath" /GRANT:Todos,FULL /GRANT:Everyone,FULL /UNLIMITED 2>$null

    Write-Host "  > Ativando proteção por senha (Desativando Guest)..."
    net user Guest /active:no 2>$null
    net user Convidado /active:no 2>$null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "everyoneincludesanonymous" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "restrictnullsessaccess" -Value 1 -Type DWord -Force
}

function Install-ChocoPrograms {
    Write-Host "Iniciando Gerenciador de Pacotes Chocolatey..."

    # LOCATE PACKAGES.CONGI
    $scriptDir = $PSScriptRoot
	$rootFolder = Split-Path -Parent $scriptDir
    $configFile = Join-Path $rootFolder "chocolatey\packages.config"

    if (-not (Test-Path $configFile)) {
        throw "Arquivo 'packages.config' não encontrado na pasta: $scriptPath. A instalação será abortada."
    }
    Write-Host "  > Arquivo de configuração encontrado: $configFile"

    # INSTALL CHOCOLATEY
    if (!(Test-Path "$env:ProgramData\chocolatey\bin\choco.exe")) {
        Write-Host "  > Chocolatey não encontrado. Instalando..."
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) | Out-Null
            
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
        catch { throw "Falha ao baixar Chocolatey. Verifique o acesso a internet!" }
    }

    $chocoExe = "$env:ProgramData\chocolatey\bin\choco.exe"
    if (!(Test-Path $chocoExe)) { throw "Erro Crítico: Executável do Chocolatey não encontrado." }

    # EXECUTE INTALATION WITH PACKAGES.CONFIG
    Write-Host "  > Instalando aplicativos definidos em packages.config..."
    
    & $chocoExe install $configFile -y --limit-output
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  > Instalação de pacotes concluída!"
    } else {
        Write-Warning "  > Chocolatey finalizou com avisos."
    }
}

function Set-SleepTime {
    Write-Host "Ajustando energia..."
    powercfg /change standby-timeout-ac 60
    powercfg /change standby-timeout-dc 60
    powercfg /change monitor-timeout-ac 60
    powercfg /change monitor-timeout-dc 60
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
}

function Set-ComputerName($novoNome) {
    Write-Host "Alterando nome do PC para $novoNome."
    Rename-Computer -NewName $novoNome -Force
}

function New-RestorePoint {
    Write-Host "Criando Ponto de Restauração..."
    try {
        Enable-ComputerRestore -Drive "C:" -ErrorAction Stop
        Checkpoint-Computer -Description "ScriptConfig" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    } catch { Write-Warning "Falha no Ponto de Restauração. Continuando..." }
}

# =================================================================
# GUI
# =================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$gui = New-Object System.Windows.Forms.Form
$gui.Text = "Ferramenta de Configuração (Completa)"
$gui.Size = New-Object System.Drawing.Size(500, 550)
$gui.StartPosition = "CenterScreen"

$check_RestorePoint = New-Object System.Windows.Forms.CheckBox
$check_RestorePoint.Text = "Criar Ponto de Restauração"
$check_RestorePoint.Location = New-Object System.Drawing.Point(20, 20); $check_RestorePoint.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_RestorePoint)

$check_RDP = New-Object System.Windows.Forms.CheckBox
$check_RDP.Text = "Habilitar RDP (Sem NLA + Firewall)"
$check_RDP.Location = New-Object System.Drawing.Point(20, 50); $check_RDP.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_RDP)

$check_Performance = New-Object System.Windows.Forms.CheckBox
$check_Performance.Text = "Desempenho (C/ Miniaturas e Arrastar)"
$check_Performance.Location = New-Object System.Drawing.Point(20, 80); $check_Performance.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_Performance)

$check_AutoUpdates = New-Object System.Windows.Forms.CheckBox
$check_AutoUpdates.Text = "Configurar Updates (Oficial + MS Products)"
$check_AutoUpdates.Location = New-Object System.Drawing.Point(20, 110); $check_AutoUpdates.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_AutoUpdates)

$check_TelnetSMB = New-Object System.Windows.Forms.CheckBox
$check_TelnetSMB.Text = "Habilitar Telnet e SMBv1 (Cliente)"
$check_TelnetSMB.Location = New-Object System.Drawing.Point(20, 140); $check_TelnetSMB.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_TelnetSMB)

$check_NetSharing = New-Object System.Windows.Forms.CheckBox
$check_NetSharing.Text = "Habilitar Compartilhamento de Rede (Seguro)"
$check_NetSharing.Location = New-Object System.Drawing.Point(20, 170); $check_NetSharing.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_NetSharing)

$check_SleepTime = New-Object System.Windows.Forms.CheckBox
$check_SleepTime.Text = "Ajustar Energia (1 Hora / Sem Hibernar)"
$check_SleepTime.Location = New-Object System.Drawing.Point(20, 200); $check_SleepTime.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_SleepTime)

$check_DisableUAC = New-Object System.Windows.Forms.CheckBox
$check_DisableUAC.Text = "Desativar UAC (Requer Reinício)"
$check_DisableUAC.Location = New-Object System.Drawing.Point(20, 230); $check_DisableUAC.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_DisableUAC)

$check_AdminUser = New-Object System.Windows.Forms.CheckBox
$check_AdminUser.Text = "Habilitar Admin e definir senha:"
$check_AdminUser.Location = New-Object System.Drawing.Point(20, 270); $check_AdminUser.Size = New-Object System.Drawing.Size(200, 20)
$gui.Controls.Add($check_AdminUser)

$text_AdminPass = New-Object System.Windows.Forms.TextBox
$text_AdminPass.Location = New-Object System.Drawing.Point(230, 270); $text_AdminPass.Size = New-Object System.Drawing.Size(240, 20); $text_AdminPass.UseSystemPasswordChar = $true
$gui.Controls.Add($text_AdminPass)

$check_ComputerName = New-Object System.Windows.Forms.CheckBox
$check_ComputerName.Text = "Alterar Nome do PC para:"
$check_ComputerName.Location = New-Object System.Drawing.Point(20, 310); $check_ComputerName.Size = New-Object System.Drawing.Size(200, 20)
$gui.Controls.Add($check_ComputerName)

$text_ComputerName = New-Object System.Windows.Forms.TextBox
$text_ComputerName.Location = New-Object System.Drawing.Point(230, 310); $text_ComputerName.Size = New-Object System.Drawing.Size(240, 20)
$gui.Controls.Add($text_ComputerName)

$check_InstallApps = New-Object System.Windows.Forms.CheckBox
$check_InstallApps.Text = "Instalar Apps Básicos (Chrome, Adobe, Java...)"
$check_InstallApps.Location = New-Object System.Drawing.Point(20, 350)
$check_InstallApps.Size = New-Object System.Drawing.Size(460, 20)
$gui.Controls.Add($check_InstallApps)


$executeButton = New-Object System.Windows.Forms.Button
$executeButton.Text = "APLICAR CONFIGURAÇÕES"
$executeButton.Location = New-Object System.Drawing.Point(100, 420)
$executeButton.Size = New-Object System.Drawing.Size(300, 50)
$executeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$gui.Controls.Add($executeButton)


# =================================================================
# EXECUTION LOGIC
# =================================================================

function Invoke-ConfigStep {
    param ([string]$Description, [scriptblock]$Action)
    Write-Host "---`nINICIANDO: $Description"
    try { & $Action -ErrorAction Stop; Write-Host "SUCESSO: $Description" }
    catch { $msg = "FALHA: $Description. $($_.Exception.Message)"; Write-Warning $msg; $Global:listaDeErros.Add($msg) | Out-Null }
}

$executeButton.Add_Click({
    $Global:restartNeeded = $false
    $Global:listaDeErros = New-Object System.Collections.Generic.List[string]
    $gui.Hide()

    if ($check_RestorePoint.Checked) { Invoke-ConfigStep "Criar Ponto de Restauração" { New-RestorePoint } }
    if ($check_RDP.Checked) { Invoke-ConfigStep "Habilitar RDP" { Set-EnableRDP } }
    if ($check_Performance.Checked) { Invoke-ConfigStep "Visual Personalizado" { Set-BestPerformance } }
    if ($check_AutoUpdates.Checked) { Invoke-ConfigStep "Configurar Updates" { Set-AutoUpdates } }
    if ($check_TelnetSMB.Checked) { Invoke-ConfigStep "Habilitar Telnet e SMBv1" { Enable-TelnetAndSMB } }
    if ($check_NetSharing.Checked) { 
        Invoke-ConfigStep "Habilitar Firewall" { Set-NetworkSharing }
        Invoke-ConfigStep "Configurar Pasta Pública" { Set-AdvancedSharing }
    }
    if ($check_SleepTime.Checked) { Invoke-ConfigStep "Ajustar Energia" { Set-SleepTime } }
    if ($check_AdminUser.Checked -and $text_AdminPass.Text -ne "") { Invoke-ConfigStep "Habilitar Admin" { Set-AdminUser $text_AdminPass.Text } }
    
    if ($check_InstallApps.Checked) { 
        Invoke-ConfigStep "Instalar Programas (Chocolatey)" { Install-ChocoPrograms }
    }

    if ($check_DisableUAC.Checked) { Invoke-ConfigStep "Desativar UAC" { Set-DisableUAC; $Global:restartNeeded = $true } }
    if ($check_ComputerName.Checked -and $text_ComputerName.Text -ne "") { Invoke-ConfigStep "Alterar Nome do PC" { Set-ComputerName $text_ComputerName.Text; $Global:restartNeeded = $true } }

    Write-Host "---`nConfiguração concluída."
    
    if ($Global:listaDeErros.Count -gt 0) {
        $erros = $Global:listaDeErros -join [Environment]::NewLine
        [System.Windows.Forms.MessageBox]::Show("Erros ocorreram:`n`n$erros", "Aviso")
    } elseif (-not $Global:restartNeeded) {
        [System.Windows.Forms.MessageBox]::Show("Sucesso!", "Concluído")
    }
    
    if ($Global:restartNeeded) {
        [System.Windows.Forms.MessageBox]::Show("Reiniciando em instantes...", "Reinício Necessário")
        Restart-Computer -Force
    }
    $gui.Close()
})

$gui.ShowDialog() | Out-Null