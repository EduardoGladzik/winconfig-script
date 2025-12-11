function Get-SystemReport {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $reportFile = "$desktopPath\Relatorio_$($env:COMPUTERNAME).txt"

    Write-Host "Coletando informações do sistema..." -ForegroundColor Cyan

    # --- HEADER AND COMPUTER NAME ---
    $sysInfo = Get-ComputerInfo
    $output = @()
    $output += "========================================================"
    $output += " RELATÓRIO DE INFORMAÇÕES - $($env:COMPUTERNAME)"
    $output += " Data: $(Get-Date)"
    $output += "========================================================"
    $output += ""
    $output += "[SISTEMA]"
    $output += "Nome do PC:     $($sysInfo.CsName)"
    $output += "Fabricante:     $($sysInfo.CsManufacturer)"
    $output += "Modelo:         $($sysInfo.CsModel)"
    $output += "Sistema:        $($sysInfo.OsName)"
    $output += "Serial (BIOS):  $((Get-WmiObject Win32_Bios).SerialNumber)"
    $output += ""

    # --- ACTIVE USERS ---
    $output += "[USUÁRIOS LOCAIS ATIVOS]"
    $output += "--------------------------------------------------------"
    
    # filter local users that are note disabled
    $users = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True AND Disabled=False"
    
    foreach ($u in $users) {
        # Verify if user is admin
        $isAdmin = "Não"
        $groups = (Get-WmiObject Win32_GroupUser | Where-Object { $_.PartComponent -match "Name=`"$($u.Name)`"" }).GroupComponent
        if ($groups -match "Administrators" -or $groups -match "Administradores") { $isAdmin = "SIM" }

        $output += "Usuario:  $($u.Name)"
        $output += "Admin:    $isAdmin"
        $output += "Status:   Ativo"
        $output += ""
    }

    # --- STATIC IP ADRESS ---
    $output += "[CONFIGURAÇÕES DE IP FIXO"
    $output += "--------------------------------------------------------"
    
    # Search for adapters with configurated ip and disabled DHCP
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    $foundStatic = $false

    foreach ($nic in $adapters) {
        if (-not $nic.DHCPEnabled) {
            $foundStatic = $true
            $output += "Adaptador: $($nic.Description)"
            $output += "MAC:       $($nic.MACAddress)"
            $output += "IP:        $($nic.IPAddress[0])"
            $output += "Mascara:   $($nic.IPSubnet[0])"
            $output += "Gateway:   $($nic.DefaultIPGateway)"
            
            $dns = $nic.DNSServerSearchOrder -join ", "
            $output += "DNS:       $dns"
            $output += "-------------------"
        }
    }

    if (-not $foundStatic) {
        $output += "Nenhum IP Fixo detectado."
    }
    $output += ""

    # --- PRINTERS ---
    $output += "[IMPRESSORAS INSTALADAS]"
    $output += "--------------------------------------------------------"
    
    $printers = Get-WmiObject Win32_Printer
    foreach ($p in $printers) {
        $output += "Nome:      $($p.Name)"
        $output += "Porta:     $($p.PortName)"
        $output += "Driver:    $($p.DriverName)"
        if ($p.Default) { $output += "STATUS:    (PADRÃO)" }
        if ($p.Shared)  { $output += "COMPART.:  Sim ($($p.ShareName))" }
        $output += "..."
    }

    # --- SAVE FILE ---
    $output | Out-File -FilePath $reportFile -Encoding UTF8
    
    Write-Host "Relatório salvo com sucesso em:" -ForegroundColor Green
    Write-Host "$reportFile" -ForegroundColor Yellow
    Write-Host ""
    
    # opens the report automaticaly
    Invoke-Item $reportFile
}

Get-SystemReport