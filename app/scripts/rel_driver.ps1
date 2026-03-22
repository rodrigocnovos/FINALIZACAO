devmgmt.msc

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano
$form.Size = New-Object Drawing.Size(300, 150)  # Aumentamos a altura para acomodar as checkboxes
$form.StartPosition = "CenterScreen"




# Função para abrir uma pesquisa no Google com o Hardware ID
function OpenGoogleSearch($hardwareID) {
    $escapedQuery = [System.Uri]::EscapeDataString($hardwareID)
    $searchURL = "https://www.google.com/search?q=$escapedQuery"
    Start-Process $searchURL
}

# Obter todos os dispositivos sem driver
$devicesWithoutDriver = @(Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 })


# Obtém informações sobre a placa de vídeo
$videoAdapters = @(Get-WmiObject -Class Win32_VideoController)



foreach ($videoAdapter in $videoAdapters) {
    
    $video_PT = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Adaptador de Vídeo Básico da Microsoft"))
    $video_EN = "Microsoft Basic Display Driver"
    $descricao = $videoAdapter.Description
    # Verifica se o driver é genérico
    if ($descricao -eq $video_PT -or $descricao -eq $video_EN ) {
        $alertVideo =  "O driver genérico está instalado na placa de vídeo."
        $idPlacaVideo = $videoAdapter.PNPDeviceID
    } #else{
    #     Write-Host "$video_PT é diferente de $descricao "
    # }
}



$lastDriver = $devicesWithoutDriver.count


$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Foram encontrados $lastDriver drivers faltantes."))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$labe2 = New-Object Windows.Forms.Label
$labe2.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("$alertVideo"))
$labe2.Location = New-Object Drawing.Point(20, 40)
$labe2.AutoSize = $true
$form.Controls.Add($labe2)



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

    if ($idPlacaVideo) {
        OpenGoogleSearch "$idPlacaVideo"
        # write-host $idPlacaVideo

    }
    
    
    
    $form.Close()
})
$form.Controls.Add($buttonOK)

$form.ShowDialog()