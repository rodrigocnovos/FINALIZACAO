devmgmt.msc

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano
$form.Size = New-Object Drawing.Size(300, 150)  # Aumentamos a altura para acomodar as checkboxes
$form.StartPosition = "CenterScreen"




# Função para abrir uma pesquisa no Google com o Hardware ID
function OpenGoogleSearch($hardwareID) {
    $searchURL = "https://www.google.com/search?q=$hardwareID"
    Start-Process $searchURL
}

# Obter todos os dispositivos sem driver
$devicesWithoutDriver = @(Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 })


# Obtém informações sobre a placa de vídeo
$videoAdapter = Get-WmiObject -Class Win32_VideoController

$videoAdapter

$video = $videoAdapter.Description

$video

$video_PT = "Adaptador de Vídeo Básico da Microsoft"
$video_EN = "Microsoft Basic Display Driver"

# Verifica se o driver é genérico
if ($video -eq $video_PT -or $video -eq $video_EN ) {
    $alertVideo =  "O driver genérico está instalado na placa de vídeo."
    Write-Host "Vídeo básico $alertVideo"
} else{
    Write-Host "Diferente $video"
}

$lastDriver = $devicesWithoutDriver.count


$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Foram encontrados $lastDriver drivers faltantes.  $alertVideo"))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)



$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(100, 60)
$buttonOK.Size = New-Object Drawing.Size(90, 40)
if ($lastDriver -eq 0) {
    $buttonOK.Text = "OK"
    <# Action to perform if the condition is true #>
}else {
    $buttonOK.Text = "Pesquisar na internet"
    
}

$buttonOK.Enabled = $true
$buttonOK.Add_Click({  
    # Iterar pelos dispositivos sem driver
    foreach ($device in $devicesWithoutDriver) {
        

        $hardwareID = $device.PNPDeviceID
        # Write-Host "Dispositivo sem driver encontrado. Hardware ID: $hardwareID"
        
        
        # Abrir pesquisa no Google com o Hardware ID
        OpenGoogleSearch $hardwareID
    }
    
    
    
    $form.Close()
})
$form.Controls.Add($buttonOK)

$form.ShowDialog()