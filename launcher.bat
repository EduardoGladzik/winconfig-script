@echo off
set "WORK_DIR=%~dp0"
set "TEMP_DIR=%SystemRoot%\Temp\WinConfig"
set "FLAG_FILE=%SystemRoot%\Temp\WinConfig_Stage2.flag"

:: Verify admin permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando privilegios de Administrador...
    powershell.exe -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: =======================================================
:: Report and Winconfig
:: =======================================================
echo.
echo [PASSO 1] Gerando Relatorios...
powershell.exe -ExecutionPolicy Bypass -File "%WORK_DIR%scripts\report.ps1"

echo.
echo [PASSO 2] Iniciando Instalação dos aplicativos padrão...
start /wait powershell.exe -ExecutionPolicy Bypass -File "%WORK_DIR%scripts\apps.ps1"

echo.
echo [PASSO 3] Iniciando GUI de Configuracao...
start /wait powershell.exe -ExecutionPolicy Bypass -File "%WORK_DIR%scripts\winconfig.ps1"

echo.
echo Processo finalizado com sucesso!
pause
exit