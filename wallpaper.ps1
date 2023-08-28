# Caminho completo da imagem que você deseja definir como papel de parede
$imagePath = "G:\backup rodrigo\script\startmenu 1.9.a\wallpaper\w1.jpg"

# Caminho da pasta "Imagens" no perfil do usuário
$targetFolderPath = [System.IO.Path]::Combine($env:USERPROFILE, "Pictures")

# Verifica se a pasta "Imagens" existe, se não, cria a pasta
if (-Not (Test-Path $targetFolderPath)) {
    New-Item -ItemType Directory -Path $targetFolderPath | Out-Null
}

# Copia a imagem para a pasta "Imagens"
$targetImagePath = [System.IO.Path]::Combine($targetFolderPath, (Get-Item $imagePath).Name)
Copy-Item $imagePath -Destination $targetImagePath -Force

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
