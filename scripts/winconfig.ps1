Add-Type -AssemblyName System.Windows.Forms

# =================================================================
# Windows functions
# =================================================================

function Disable-UAC {
    Write-Host "Desativando o UAC..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Type DWord -Force
}

function Enable-RDP {
    Write-Host "Configurando Área de Trabalho Remota (RDP)..."
    Write-Host "  > Ativando conexões RDP..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 -Type DWord -Force

    Write-Host "  > Desativando exigência de NLA (Autenticação de Nível de Rede)..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 0 -Type DWord -Force

    Write-Host "  > Abrindo portas no Firewall..."
    netsh advfirewall firewall set rule group="Ambiente de Trabalho Remoto" new enable=Yes
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes
    netsh advfirewall firewall add rule name="RDP-Manual-TCP-3389" dir=in action=allow protocol=TCP localport=3389
}

function Set-BestPerformance {
    Write-Host "Alterando configurações de desempenho..."

    $explorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    $desktopPath = "HKCU:\Control Panel\Desktop"
    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	
    Set-ItemProperty -Path $explorerPath -Name "VisualFXSetting" -Value 3 -Type DWord -Force

    $mask = [byte[]](0x90, 0x12, 0x01, 0x80, 0x10, 0x00, 0x00, 0x00)
    Set-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -Value $mask -Type Binary -Force
	
	# Disable
	Set-ItemProperty -Path $desktopPath -Name "MinAnimate" -Value 0 -Type String -Force
	Set-ItemProperty -Path $advancedPath -Name "DisablePreviewDesktop" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $advancedPath -Name "ListviewShadow" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $advancedPath -Name "TaskbarAnimations" -Value 0 -Type DWord
	
	# Enable
    Set-ItemProperty -Path $desktopPath -Name "DragFullWindows" -Value 1 -Type String -Force
    Set-ItemProperty -Path $advancedPath -Name "IconsOnly" -Value 0 -Type DWord -Force
	Set-ItemProperty -Path $desktopPath -Name "FontSmoothing" -Value 2 -Type String -Force


    Write-Host "  > Reiniciando Windows Explorer..."
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

function Enable-AdminUser() {
    Write-Host "Habilitando usuário 'Administrador'..."
	$scriptDir = $PSScriptRoot
	$rootFolder = Split-Path -Parent $scriptDir
    $configFile = Join-Path $rootFolder "password\password.txt"
	$password = (Get-Content -Path $configFile -Raw).Trim()
    net user Administrador $password

    net user Administrador /active:yes
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
        $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
    } catch { Write-Host "    (Serviço já pode estar ativo)" }

    $UXKey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
    if (!(Test-Path $UXKey)) { New-Item -Path $UXKey -Force }
    Set-ItemProperty -Path $UXKey -Name "IsContinuousInnovationOptedIn" -Value 1 -Type DWord -Force

    sc.exe config wuauserv start= auto; sc.exe start wuauserv 2>$null
    sc.exe config bits start= auto; sc.exe start bits 2>$null
    sc.exe config UsoSvc start= auto; sc.exe start UsoSvc 2>$null

    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Recurse -Force -ErrorAction SilentlyContinue

    Start-Process -FilePath "UsoClient.exe" -ArgumentList "StartScan" -ErrorAction SilentlyContinue
}

function Enable-TelnetAndSMB {
    Write-Host "Habilitando Cliente Telnet..."
    Enable-WindowsOptionalFeature -Online -FeatureName "TelnetClient" -All -NoRestart

    Write-Host "Configurando SMB 1.0 (Apenas Cliente)..."
    # O comando nativo lida automaticamente com dependências se usar o -All
    Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client" -All -NoRestart
	Start-Sleep -Seconds 5
	Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Server" -NoRestart
	Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Deprecation" -NoRestart
}

function Set-NetworkSharing {
    Write-Host "Ajustando configurações de compartilhamento de rede..."
    $gruposFile = @("Compartilhamento de Arquivo e Impressora", "Partilha de Ficheiros e Impressoras", "File and Printer Sharing")
    $gruposDiscovery = @("Descoberta de Rede", "Deteção de Rede", "Network Discovery")

    foreach ($nome in $gruposFile) { netsh advfirewall firewall set rule group="$nome" new enable=Yes }
    foreach ($nome in $gruposDiscovery) { netsh advfirewall firewall set rule group="$nome" new enable=Yes }

    # Fallback
    netsh advfirewall firewall add rule name="SMB-Manual-TCP-445" dir=in action=allow protocol=TCP localport=445
    netsh advfirewall firewall add rule name="NetBIOS-Manual-TCP-139" dir=in action=allow protocol=TCP localport=139
    netsh advfirewall firewall add rule name="NetBIOS-Manual-UDP" dir=in action=allow protocol=UDP localport=137,138
    netsh advfirewall firewall add rule name="ICMP-Ping-Manual" dir=in action=allow protocol=ICMPv4
}

function Set-AdvancedSharing {
    Write-Host "Ajustando configurações de compartilhamento avançadas..."
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

function Set-SleepTime {
    Write-Host "Ajustando configurações de economia de energia..."
    powercfg /change standby-timeout-ac 60
    powercfg /change standby-timeout-dc 60
    powercfg /change monitor-timeout-ac 60
    powercfg /change monitor-timeout-dc 60
    powercfg /change hibernate-timeout-ac 0
    powercfg /change hibernate-timeout-dc 0
}

function Set-ComputerName {
	$scriptDir = $PSScriptRoot
	$rootFolder = Split-Path -Parent $scriptDir
	$reportPath = Join-Path $rootFolder "relatorio.txt"
	$content = Get-Content -Path $reportPath
	$targetLine = $content | Where-Object { $_ -match "Nome do PC:"}
	
	if($targetLine) {
		$parts = $targetLine -split ":"
	}
	
	$newName = $parts[1].Trim()
    Write-Host "Alterando nome do PC..."
    Rename-Computer -NewName $newName -Force
}

function Create-RestorePoint {
    Write-Host "Criando Ponto de Restauração..."
    try {
        Enable-ComputerRestore -Drive "C:" -ErrorAction Stop
        Checkpoint-Computer -Description "ScriptConfig" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    } catch { Write-Warning "Falha no Ponto de Restauração. Continuando..." }
}

# =================================================================
# EXECUTION LOGIC
# =================================================================

function Invoke-ConfigStep {
    param ([string]$Description, [scriptblock]$Action)
    Write-Host "---`nINICIANDO: $Description"
    try { & $Action -ErrorAction Stop; Write-Host "SUCESSO: $Description" }
    catch { $msg = "FALHA: $Description. $($_.Exception.Message)"; Write-Warning $msg; $Global:listaDeErros.Add($msg) }
}

$Global:listaDeErros = New-Object System.Collections.Generic.List[string]

Invoke-ConfigStep "Habilitar RDP" { Enable-RDP }
Invoke-ConfigStep "Visual Personalizado" { Set-BestPerformance }
Invoke-ConfigStep "Configurar Updates" { Set-AutoUpdates }
Invoke-ConfigStep "Habilitar Telnet e SMBv1" { Enable-TelnetAndSMB } 
Invoke-ConfigStep "Habilitar Firewall" { Set-NetworkSharing }
Invoke-ConfigStep "Configurar Pasta Pública" { Set-AdvancedSharing }
Invoke-ConfigStep "Ajustar Energia" { Set-SleepTime }
Invoke-ConfigStep "Habilitar Admin" { Enable-AdminUser }
Invoke-ConfigStep "Desativar UAC" { Disable-UAC }
Invoke-ConfigStep "Alterar Nome do PC" { Set-ComputerName }
Invoke-ConfigStep "Criar Ponto de Restauração" { Create-RestorePoint }

Write-Host "---`nConfiguração concluída."

if ($Global:listaDeErros.Count -gt 0) {
	$erros = $Global:listaDeErros -join [Environment]::NewLine
	[System.Windows.Forms.MessageBox]::Show("Erros ocorreram:`n`n$erros", "Aviso")
} elseif (-not $Global:restartNeeded) {
	[System.Windows.Forms.MessageBox]::Show("Sucesso!", "Concluído")
}

[System.Windows.Forms.MessageBox]::Show("Reiniciando em instantes...", "Reinício Necessário")
# Restart-Computer -Force