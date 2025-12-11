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

Install-ChocoPrograms