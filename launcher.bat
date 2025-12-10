@echo off

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando privilegios de Administrador...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Iniciando a Ferramenta de Configuracao...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\script-winconfig.ps1"

echo.
echo Processo terminado. Pressione qualquer tecla para fechar...
pause > nul