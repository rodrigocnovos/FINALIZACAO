# Função para verificar atalhos quebrados e duplicados no desktop
function Verificar-AtalhosQuebradosEDuplicados {
    # Caminho do desktop do usuário atual
    $desktopPath = [Environment]::GetFolderPath("Desktop")

    # Filtrar atalhos (.lnk)
    $shortcuts = Get-ChildItem -Path $desktopPath -Filter "*.lnk"

    # Lista para armazenar atalhos quebrados e duplicados
    $atalhosQuebrados = @()
    $atalhosDestino = @{}  # Dicionário para armazenar destinos e verificar duplicidade
    $atalhosParaRemover = @()  # Lista de atalhos a serem removidos

    # Verificar cada atalho
    foreach ($shortcut in $shortcuts) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcutPath = $shortcut.FullName
        $targetPath = $shell.CreateShortcut($shortcutPath).TargetPath

        # Verificar se o atalho é quebrado
        if (-not (Test-Path $targetPath)) {
            $atalhosQuebrados += [PSCustomObject]@{
                Atalho = $shortcutPath
                Destino = $targetPath
                Tipo = "Quebrado"
            }
        } else {
            # Verificar duplicidade de destino
            if ($atalhosDestino.ContainsKey($targetPath)) {
                $atalhosQuebrados += [PSCustomObject]@{
                    Atalho = $shortcutPath
                    Destino = $targetPath
                    Tipo = "Duplicado"
                }
                # Adicionar o atalho duplicado para remoção
                $atalhosParaRemover += $shortcutPath
            } else {
                $atalhosDestino[$targetPath] = $shortcutPath
            }
        }
    }

    # Retorna a lista de atalhos quebrados ou duplicados e os atalhos para remoção
    return [PSCustomObject]@{
        AtalhosQuebrados = $atalhosQuebrados
        AtalhosParaRemover = $atalhosParaRemover
    }
}

# Função para abrir o navegador com o site para baixar os atalhos
function Abrir-SiteParaBaixarAtalho {
    # URL do servidor
    $url = "http://177.107.97.38:9123"
    # Abrir o site no navegador padrão
    Start-Process $url
}

# Parte principal do script
# Configurar papel de parede, copiar ícones, etc.
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem

if ($osInfo.Caption -like "*Windows 7*") {
    $imagePath = ".\wallpaper\w7.jpg"
}
elseif ($osInfo.Caption -like "*Windows 8*") {
    $imagePath = ".\wallpaper\w8.jpg"
}
elseif ($osInfo.Caption -like "*Windows 10*") {
    $imagePath = ".\wallpaper\w10.jpg"
}
elseif ($osInfo.Caption -like "*Windows 11*") {
    $imagePath = ".\wallpaper\w11.jpg"
}

Write-Host $imagePath

# Caminho dos ícones
$iconsPath = ".\ico\*.url"
$iconsPathico = ".\ico\*.ico"
# Caminho para o desktop do usuário corrente
$desktopPath = [Environment]::GetFolderPath("Desktop")
Remove-Item $desktopPath\* -Force -Recurse -ErrorAction SilentlyContinue 2>$null1

# Copiar imagens e ícones
$targetFolderPath = "C:\Users\Public\Pictures"
if (-Not (Test-Path $targetFolderPath)) {
    New-Item -ItemType Directory -Path $targetFolderPath | Out-Null
}
$targetImagePath = [System.IO.Path]::Combine($targetFolderPath, (Get-Item $imagePath).Name)
Copy-Item $imagePath -Destination $targetImagePath -Force
Copy-Item $iconsPathico -Destination $targetFolderPath -Force
$iconesGeral = ".\Desktop\*"
Copy-Item $iconesGeral -Destination $desktopPath
Copy-Item $iconsPath -Destination $desktopPath -Force
Unblock-File $desktopPath\*

# Definir papel de parede
$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $targetImagePath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)

# Verificar atalhos quebrados e duplicados
$resultado = Verificar-AtalhosQuebradosEDuplicados

# Exibir alerta se houver atalhos quebrados ou duplicados
if ($resultado.AtalhosQuebrados.Count -gt 0) {
    $mensagem = "Os seguintes atalhos estão quebrados: `n`n"
    foreach ($atalho in $resultado.AtalhosQuebrados) {
        $mensagem += "$($atalho.Tipo): $($atalho.Atalho) -> Destino: $($atalho.Destino)`n`n"
    }

    # Exibir MessageBox com o botão "BAIXAR PROGRAMAS DO SERVIDOR"
    Add-Type -AssemblyName PresentationCore, PresentationFramework
    $resultadoMensagem = [System.Windows.MessageBox]::Show($mensagem, "Atalhos Quebrados ou Duplicados", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

    # Se o usuário clicar em "Yes" (Baixar Programas do Servidor)
    if ($resultadoMensagem -eq [System.Windows.MessageBoxResult]::Yes) {
        Abrir-SiteParaBaixarAtalho
    }
} else {
    Write-Host "Nenhum atalho quebrado ou duplicado encontrado."
}

# Remover atalhos duplicados
if ($resultado.AtalhosParaRemover.Count -gt 0) {
    foreach ($atalho in $resultado.AtalhosParaRemover) {
        Write-Host "Removendo atalho duplicado: $atalho"
        Remove-Item -Path $atalho -Force
    }
} else {
    Write-Host "Nenhum atalho duplicado encontrado para remoção."
}

# Continuar com o restante do script, como aplicação de configurações no registro
$sourceFilePath = ".\DefaultLayouts.xml"
$destinationFolderPath = "$env:LocalAppData\Microsoft\Windows\Shell"
Copy-Item -Path $sourceFilePath -Destination $destinationFolderPath

Remove-Item -Path C:\Users\Public\Desktop\*  -Force
