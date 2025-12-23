@echo off
set "WORK_DIR=%~dp0"
set "TEMP_DIR=%SystemRoot%\Temp\WinConfig"

:: Verify admin permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando privilegios de administrador...
    powershell.exe -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Chama a GUI
echo Iniciando Interface...
powershell.exe -ExecutionPolicy Bypass -File "%WORK_DIR%scripts\interface.ps1"

exit