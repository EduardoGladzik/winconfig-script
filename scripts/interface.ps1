Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- Paths ---
$scriptDir = $PSScriptRoot
$pathReport    = Join-Path $scriptDir "report.ps1"
$pathApps      = Join-Path $scriptDir "apps.ps1"
$pathWinConfig = Join-Path $scriptDir "winconfig.ps1"

# --- GUI design in XAML ---
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Alfasys Setup Assistant" Height="450" Width="400" WindowStartupLocation="CenterScreen"
        ResizeMode="CanMinimize" Background="#1E1E1E">
    
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="5"/>
                </Style>
            </Style.Resources>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#DDDDDD"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Margin" Value="0,10,0,10"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Segoe UI"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="LAB SETUP AUTOMATION" Foreground="White" FontSize="24" FontWeight="Bold" HorizontalAlignment="Center"/>
            <TextBlock Text="Selecione as tarefas a executar" Foreground="#AAAAAA" FontSize="12" HorizontalAlignment="Center" Margin="0,5,0,0"/>
        </StackPanel>

        <StackPanel Grid.Row="1" VerticalAlignment="Center">
            <Border Background="#2D2D30" CornerRadius="8" Padding="15">
                <StackPanel>
                    <CheckBox Name="chkReport" Content="1. Gerar Relatório" IsChecked="True"/>
                    <CheckBox Name="chkApps" Content="2. Instalar Aplicativos" IsChecked="True"/>
                    <CheckBox Name="chkConfig" Content="3. Configurar windows" IsChecked="True"/>
                </StackPanel>
            </Border>
        </StackPanel>

        <TextBlock Name="txtStatus" Grid.Row="2" Text="Pronto para iniciar..." Foreground="#FFCC00" Margin="0,15,0,5" HorizontalAlignment="Center"/>

        <Button Name="btnRun" Grid.Row="3" Content="INICIAR PROCESSOS" Height="45" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

# --- Leitor do XAML ---
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# --- Mapeamento de Controles ---
$chkReport = $window.FindName("chkReport")
$chkApps   = $window.FindName("chkApps")
$chkConfig = $window.FindName("chkConfig")
$btnRun    = $window.FindName("btnRun")
$txtStatus = $window.FindName("txtStatus")

# --- Função de Execução ---
$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $btnRun.Content = "Executando..."
    
    # Processo 1: Relatório
    if ($chkReport.IsChecked) {
        $txtStatus.Text = "Gerando Relatório..."
        # O [System.Windows.Forms.Application]::DoEvents() força a GUI a atualizar o texto
        [System.Windows.Forms.Application]::DoEvents() 
        
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$pathReport`"" -Wait -NoNewWindow
    }

    # Processo 2: Apps
    if ($chkApps.IsChecked) {
        $txtStatus.Text = "Instalando Aplicativos..."
        [System.Windows.Forms.Application]::DoEvents()

        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$pathApps`"" -Wait 
    }

    # Processo 3: Configuração
    if ($chkConfig.IsChecked) {
        $txtStatus.Text = "Aplicando configurações..."
        [System.Windows.Forms.Application]::DoEvents()

        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$pathWinConfig`"" -Wait
    }

    $txtStatus.Text = "Processos Finalizados!"
    $txtStatus.Foreground = "Green"
    $btnRun.Content = "CONCLUÍDO"
    $btnRun.IsEnabled = $true
})

# --- Launch GUI ---
$window.ShowDialog() | Out-Null