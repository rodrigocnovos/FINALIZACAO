$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem

if ($osInfo.Caption -like "*Windows 7*") {
    # Caminho completo da imagem que você deseja definir como papel de parede
    $imagePath = ".\wallpaper\w7.jpg"    
}
elseif ($osInfo.Caption -like "*Windows 8*") {
    # Caminho completo da imagem que você deseja definir como papel de parede
    $imagePath = ".\wallpaper\w8.jpg"
}
elseif ($osInfo.Caption -like "*Windows 10*") {
    # Caminho completo da imagem que você deseja definir como papel de parede
    $imagePath = ".\wallpaper\w10.jpg"
}
elseif ($osInfo.Caption -like "*Windows 11*") {
    # Caminho completo da imagem que você deseja definir como papel de parede
    $imagePath = ".\wallpaper\w11.jpg"
    
}

Write-Host $imagePath
#Caminho dos ícones
$iconsPath = ".\ico\*.url"
$iconsPathico = ".\ico\*.ico"

# Caminho da pasta "Imagens" no perfil no perfil púbolico
# $targetFolderPath = [System.IO.Path]::combine($env:USERPROFILE, "Pictures")
$targetFolderPath = "C:\Users\Public\Pictures"


# #Caminho para o desktop do usuário corrente
$desktopPath = [Environment]::GetFolderPath("Desktop")
# Remove-Item $desktopPath\* -Force -Recurse

# # Excluir arquivos do desktop público
# $publicDesktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")
# Remove-Item "$publicDesktopPath\*" -Force -Recurse


# Verifica se a pasta "Imagens" existe, se não, cria a pasta
if (-Not (Test-Path $targetFolderPath)) {
    New-Item -ItemType Directory -Path $targetFolderPath | Out-Null
}

# Copia a imagem para a pasta "Imagens"
$targetImagePath = [System.IO.Path]::Combine($targetFolderPath, (Get-Item $imagePath).Name)
Write-Host " caminho para o $imagePath  a pasta do final $targetImagePath"
Copy-Item $imagePath -Destination $targetImagePath -Force

Write-Host "caminho para os icones geral $iconsPathico para a pasta $targetFolderPath"
Copy-Item $iconsPathico -Destination $targetFolderPath -Force

#Copia os ícones dos programas padrões 
$iconesGeral = ".\Desktop\*"
Copy-Item $iconesGeral -Destination $desktopPath
Write-Host "caminho icones geral local e destino"
Write-Host $iconesGeral $desktopPath

#Copia os ícones para a área de trabalho corrente do usuário

Write-Host "caminho para os icones e desino"
Write-Host $iconsPath $desktopPath
Copy-Item $iconsPath -Destination $desktopPath -Force



# Definir o valor do Registro para criar pontos de restauração a cada 1 minuto
$regPath = "HKCU:\Control Panel\Desktop"
$regName = "WallpaperStyle"
$regNameValue = "2"

# Definir o novo valor (1 minuto) temporariamente
$regValueTemp = 1

# Definir o novo valor temporariamente
Set-ItemProperty -Path $regPath -Name $regName -Value $regNameValue




# Define a nova imagem como papel de parede
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

# Importa a função necessária da DLL do Windows
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Chama a função para definir o papel de parede
[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $targetImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)



#  "Copiando o modelo padronizado do layout do menu"
$sourceFilePath = ".\DefaultLayouts.xml"
$destinationFolderPath = "$env:LocalAppData\Microsoft\Windows\Shell"
Write-Host "pasta do xml $destinationFolderPath"

Copy-Item -Path $sourceFilePath -Destination $destinationFolderPath

$regeditPath = Join-Path $env:SystemRoot "regedit.exe"
Start-Process $regeditPath -ArgumentList "/s  .\icon_homeuser_computer.reg"  -Wait

if ( $imagePath -eq ".\wallpaper\w10.jpg") {
    
    Start-Process $regeditPath -ArgumentList "/s  .\regMenu.reg"  -Wait
    Start-Process $regeditPath -ArgumentList "/s  .\DefaultLayouts.reg" -Wait
    Start-Process $regeditPath -ArgumentList "/s  .\logowin10.reg" -Wait
    
}
if ($imagePath -eq ".\wallpaper\w11.jpg") {

if (Test-Path $env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\){

    $arquivos_start = Get-ChildItem $env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start*

    foreach ($arquivo in $arquivos_start)
    {
        Copy-Item ".\win11_files\start.bin" -Destination $arquivo -Force 
        Write-Host $arquivo
    }

}

}

Stop-Process -Name Explorer -Force