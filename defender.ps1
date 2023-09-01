#Abrir as configurações do windows defender

$opcoes = "windowsdefender://ThreatSettings"
$programa = "explorer.exe"

Start-Process $programa -ArgumentList $opcoes -NoNewWindow -PassThru -Wait



Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano
$form.Size = New-Object Drawing.Size(300, 150)  # Aumentamos a altura para acomodar as checkboxes
$form.StartPosition = "CenterScreen"

$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("DESATIVE O ANTIVIRUS TEMPORARIAMENTE"))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(100, 60)
$buttonOK.Size = New-Object Drawing.Size(90, 40)
$buttonOK.Text = "OK"


$buttonOK.Enabled = $true
$buttonOK.Add_Click({
    #Desativa a proteção do antivirus
    Set-MpPreference -DisableRealtimeMonitoring $true -Force      
    $form.Close()
})
$form.Controls.Add($buttonOK)

$form.ShowDialog()



# function WindowsDefenderProtection {
#     param (
#         [switch]$Disable
#     )

#     if ($Disable) {
#         # Desabilita as opções do Windows Defender
#         Set-MpPreference -DisableRealtimeMonitoring $true -Force  -DisableIntrusionPreventionSystem $true  -DisableIOAVProtection $true  -DisablePrivacyMode $true  -DisableScriptScanning $true  -EnableControlledFolderAccess Disabled

#         Write-Host "As opções do Windows Defender foram desabilitadas."
#     } else {
#         # Habilita as opções do Windows Defender novamente
#         Set-MpPreference -DisableRealtimeMonitoring $false -DisableIntrusionPreventionSystem $false -DisableIOAVProtection $false -DisablePrivacyMode $false -DisableScriptScanning $false -EnableControlledFolderAccess Enabled

#         Write-Host "As opções do Windows Defender foram habilitadas novamente."
#     }
# }

# # Exemplo de uso para desabilitar
#  WindowsDefenderProtection -Disable

# # Exemplo de uso para habilitar novamente
# # WindowsDefenderProtection
