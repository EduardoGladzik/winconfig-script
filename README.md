Description
=============================
PowerShell script designed to automate tasks of my daily work routine.

Features
=============================
- Report: generates a report with relevant information about the computer, such as name and printer settings.
- Apps: Install apps via Windows package manager (Winget).
- Winconfig: configure settings like network sharing and sleep time.

Dependencies
=============================
Some dependencies need to be installed for the script to work. 

- Winget dependencies: install the following packages and move them to winget/libs
  - Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
  - Microsoft.UI.Xaml.2.8.x64.appx
  - Microsoft.VCLibs.x64.14.00.Desktop.appx

- Offline installers:
  - Chrome .msi installer: googlechrome.msi > move to winget/offline
  - Adobe Acrobat Reader installer: https://helpx.adobe.com/br/acrobat/kb/download-64-bit-installer.html
    - Download the zip folder and extract the files to winget/offline/AdobeReader