@echo off
REM Este script verifica se está a ser executado como Administrador
REM e lança o script PowerShell principal.

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando privilegios de Administrador...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

REM Estamos como Administrador. Vamos executar o script principal.
echo Iniciando a Ferramenta de Configuracao...
REM %~dp0 significa "a pasta onde este ficheiro .bat está"
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\script-winconfig.ps1"

echo.
echo Processo terminado. Pressione qualquer tecla para fechar...
pause > nul