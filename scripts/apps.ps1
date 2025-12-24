function Execute-InstallationFile {
    Write-Host "--- Preparando Ambiente Winget ---" -ForegroundColor Cyan
	
	$rootFolder = Split-PAth -Parent $PSScriptRoot
	$libsFolder = Join-Path $rootFolder "winget\libs"
	$offlineFolder = Join-Path $rootFolder "winget\offline"

    # Official Microsfot sources for winget dependencies
    $dependencies = @(
        "Microsoft.VCLibs.x64.14.00.Desktop.appx",
        "Microsoft.UI.Xaml.2.8.x64.appx",
        "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    )

    # Regiter and download each dependencie with a loop
    foreach ($file in $dependencies) {
        $fullPath = Join-Path $libsFolder $file
        
        if (Test-Path $fullPath) {
            Write-Host " > Instalando localmente: $file..."
            try {
                Add-AppxPackage -Path $fullPath -ForceApplicationShutdown -ErrorAction Stop
            }
            catch {
                Write-Warning "   Falha ao instalar $file. O sistema pode já ter uma versão mais recente."
            }
        } else {
            Write-Warning " Arquivo não encontrado no Pen Drive: $file"
            Write-Warning " Certifique-se de que ele está na pasta: $libsFolder"
        }
    }

    Write-Host " > Ambiente Winget preparado!" -ForegroundColor Green
    Start-Sleep -Seconds 2
	
    Write-Host "Iniciando instalação dos pacotes..."
	
	# Chrome offline install to avoid common hash problems
	$chromeMSI = Join-Path $offlineFolder "googlechrome.msi"
    
    if (Test-Path $chromeMSI) {
        Write-Host " > Instalando Google Chrome..." -ForegroundColor Yellow
        try {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$chromeMSI`" /passive /norestart" -Wait -ErrorAction Stop
            Write-Host "Chrome instalado com sucesso." -ForegroundColor Green
        } catch {
            Write-Warning "Falha ao instalar Chrome."
        }
    } else {
        Write-Warning "Instalador do Chrome não encontrado em: $chromeMSI"
    }

    # Adobe Reader offline install to optmize automation speed
    $adobeFolder = Join-Path $offlineFolder "AdobeReader"
	$adobeMSI = Join-Path $adobeFolder "AcroPro.msi"
	$adobeMSP = Join-PAth $adobeFolder "AcrobatDCx64Upd2500120997.msp"
    
    if (Test-Path $adobeMSI) {
        Write-Host " > Instalando Adobe Reader..." -ForegroundColor Yellow

        try {
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$adobeMSI`" /passive /norestart LANG_LIST=pt_BR EULA_ACCEPT=YES" -Wait -ErrorAction Stop
			reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" /v bIsSCReducedModeEnforcedEx /t REG_DWORD /d 1 /f
			Write-Host "Adobe Acrobat Reader instalado com sucesso." -ForegroundColor Green
        } catch {
            Write-Warning "Falha ao instalar Adobe Acrobat Reader.."
        }
		
		try {
			Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$adobeMSP`" /passive /norestart EULA_ACCEPT=YES" -Wait -ErrorAction Stop
		} catch {
			Write-Warning "Falha ao aplicar atualizações do Adobe Acrobat Reader."
		}
    } else {
        Write-Warning "Instalador do Adobe não encontrado em: $adobeEXE"
    }

    # find pckgs.JSON
    $configFile = Join-Path $rootFolder "winget\pckgs.JSON"

    if (-not (Test-Path $configFile)) {
        throw "Arquivo 'pckgs.JSON' não encontrado na pasta: $scriptPath. A instalação será abortada."
    }
    Write-Host "  > Arquivo de configuração encontrado: $configFile"

    # install packages via winget importing from pckgs.JSON
    Write-Host "  > Instalando aplicativos definidos no arquivo de instalação..."
    & winget import -i "$configFile" --accept-source-agreements --accept-package-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  > Instalação de pacotes concluída!"
    } else {
        Write-Warning "  > Winget finalizou com avisos. (Código: $LASTEXITCODE)"
    }
}

Execute-InstallationFile