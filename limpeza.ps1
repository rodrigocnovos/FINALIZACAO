# Carregar a biblioteca de formulários do Windows
Add-Type -AssemblyName System.Windows.Forms

# Criar um formulário invisível para garantir que a mensagem apareça no topo
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true # Garantir que esteja no topo

# Criar a janela de mensagem
$mensagem = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Começar a limpeza?"))
$titulo = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Confirmação"))
$botoes = [System.Windows.Forms.MessageBoxButtons]::YesNo
$icone = [System.Windows.Forms.MessageBoxIcon]::Question

# Exibir a caixa de diálogo em primeiro plano
$resposta = [System.Windows.Forms.MessageBox]::Show($form, $mensagem, $titulo, $botoes, $icone)

# Verificar a resposta do usuário
if ($resposta -eq [System.Windows.Forms.DialogResult]::Yes) {
    Write-Host "confirmou a limpeza."
    function Limpeza {
        # Seu código de limpeza aqui
    }
    Limpeza
} else {
    Write-Host "cancelou a limpeza"
    # Código para cancelar ou encerrar
}

# Fechar o formulário criado
$form.Dispose()
