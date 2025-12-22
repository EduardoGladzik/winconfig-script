function Execute-InstallationFile {
    Write-Host "Iniciando Gerenciador de Pacotes do WIndows..."

    # LOCATE pckgs.JSON
    $scriptDir = $PSScriptRoot
	$rootFolder = Split-Path -Parent $scriptDir
    $configFile = Join-Path $rootFolder "winget\pckgs.JSON"

    if (-not (Test-Path $configFile)) {
        throw "Arquivo 'pckgs.JSON' não encontrado na pasta: $scriptPath. A instalação será abortada."
    }
    Write-Host "  > Arquivo de configuração encontrado: $configFile"

    # EXECUTE INTALATION WITH PACKAGES.CONFIG
    Write-Host "  > Instalando aplicativos definidos no arquivo de intalação..."
    
    & winget import -i $configFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  > Instalação de pacotes concluída!"
    } else {
        Write-Warning "  > Winget finalizou com avisos."
    }
}

Execute-InstallationFile