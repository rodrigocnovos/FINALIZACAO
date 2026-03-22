Script PowerShell para abrir programas e simular comportamento humano

# Abrir Navegador e acessar URLs
Start-Process "chrome.exe" "https://www.youtube.com/watch?v=36YnV9STBqc"
Start-Sleep -Seconds 10  # Aguardar 5 segundos
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep -Seconds 2  # Aguardar 5 segundos
Start-Process "chrome.exe" "https://www.uol.com.br/"
Start-Sleep -Seconds 5  # Aguardar 5 segundos
Start-Process "chrome.exe" "https://g1.globo.com/"
Start-Sleep -Seconds 10 # Aguardar 10 segundos

# # # Abrir Microsoft Excel
Start-Process "excel.exe"
Start-Sleep -Seconds 5  # Aguardar o Excel abrir


# Obter o diretório atual
$CurrentPath = (Get-Location).Path

# Definir o caminho completo do arquivo PPTX
$FilePath = Join-Path -Path $CurrentPath -ChildPath "Arquivos/slide.pptx"

# Verificar se o arquivo existe antes de continuar
if (-Not (Test-Path -Path $FilePath)) {
    Write-Error "O arquivo 'slide.pptx' não foi encontrado no diretório atual: $CurrentPath"
    exit
}

# Criar um novo objeto COM para o aplicativo PowerPoint
$PowerPoint = New-Object -ComObject PowerPoint.Application

# Tornar o PowerPoint visível (usando o tipo correto para MsoTriState)
$PowerPoint.Visible = [Microsoft.Office.Core.MsoTriState]::msoTrue

# Abrir a apresentação
$Presentation = $PowerPoint.Presentations.Open($FilePath)

# Iniciar a apresentação em modo de exibição de slides
$SlideShow = $Presentation.SlideShowSettings.Run()

# Trazer o PowerPoint para o primeiro plano
# Add-Type @"
# using System;
# using System.Runtime.InteropServices;
# public class Win32 {
#     [DllImport("user32.dll")]
#     public static extern IntPtr GetForegroundWindow();
#     [DllImport("user32.dll")]
#     [return: MarshalAs(UnmanagedType.Bool)]
#     public static extern bool SetForegroundWindow(IntPtr hWnd);
# }
# "@

# Obter a janela do PowerPoint e trazer para o primeiro plano
$powerPointWindow = Get-Process powerpnt | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($powerPointWindow) {
    [Win32]::SetForegroundWindow($powerPointWindow.MainWindowHandle)
}


Start-Sleep -Seconds 30  # Aguardar enquanto a apresentação está em execução


# Fechar a apresentação após o término
$Presentation.Close()

# Tentar encerrar o PowerPoint pelo processo ativo
Write-Output "Encerrando o PowerPoint..."
$powerPointProcess = Get-Process -Name "powerpnt" -ErrorAction SilentlyContinue
if ($powerPointProcess) {
    Stop-Process -Id $powerPointProcess.Id -Force
    Write-Output "O PowerPoint foi encerrado com sucesso."
} else {
    Write-Warning "Nenhum processo do PowerPoint foi encontrado em execução."
}

# Liberar objetos COM da memória
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($SlideShow) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($Presentation) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($PowerPoint) | Out-Null

Write-Output "A apresentação foi concluída e todos os recursos foram liberados."







# # Abrir Windows Explorer
Start-Process "explorer.exe"
Start-Sleep -Seconds 5  # Aguardar o Explorer abrir


# Abrir Microsoft Word diretamente em um novo documento
$Word = New-Object -ComObject Word.Application
$Word.Visible = $true
$Document = $Word.Documents.Add()
$Document.Activate()

# Obter janela ativa do Word
$wordWindow = Get-Process winword | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if ($wordWindow) {
    [Win32]::SetForegroundWindow($wordWindow.MainWindowHandle)
}
Start-Sleep -Seconds 2  # Pausa para garantir foco

# Simular digitação caractere por caractere no Word
$texto1 = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Este é um documento de teste MICROFACIL de auto-digitação no Word! aguarde a conclusão antes de sair"))
$texto2 = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("No Evangelho de Mateus: Mateus 1:18-25: Aqui, lemos sobre o anúncio do nascimento de Jesus a José e o nascimento em si. Versículo 23: A virgem ficará grávida e dará à luz um filho, e o chamarão Emanuel, que significa 'Deus conosco'. No Evangelho de Lucas: Lucas 1:26-38:  Narra o anúncio do nascimento de Jesus feito pelo anjo Gabriel à Maria. Versículo 31:  Você ficará grávida e dará à luz um filho, e o chamará Jesus. Lucas 2:1-20:  Contém a famosa história do nascimento de Jesus em Belém, incluindo a visita dos pastores. Versículo 11:  Hoje, na cidade de Davi, nasceu o Salvador, que é Cristo, o Senhor. No Evangelho de João: João 1:14: Fala sobre o Verbo se tornar carne, uma referência ao nascimento de Cristo.  O Verbo se fez carne e habitou entre nós, cheio de graça e de verdade, e vimos a sua glória, glória como do unigênito do Pai. ########  FIM DO TESTE   ######"))

# Função para digitar texto simulando interação humana
function DigitarTexto {
    param (
        [string]$Texto
    )
    foreach ($char in $Texto.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait($char)
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 60)  # Pausa aleatória entre caracteres
    }
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")  # Simula pressionar "Enter" ao final do texto
}

# Ativar System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms

# Digitar os textos no Word
DigitarTexto -Texto $texto1
# Start-Sleep -Seconds 1  # Pausa entre os textos
DigitarTexto -Texto $texto2

    # Reiniciar o computador após 30 segundos (para permitir observação final)
    # Write-Output "O computador será reiniciado em 30 segundos..."
    # Start-Sleep -Seconds 30
    # Restart-Computer -Force
