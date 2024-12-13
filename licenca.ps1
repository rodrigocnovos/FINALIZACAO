Add-Type -AssemblyName System.Windows.Forms

function Check-WindowsActivationStatus {
    $activation = (Get-WmiObject -query 'select * from SoftwareLicensingProduct' | Where-Object { $_.PartialProductKey -ne $null })

    $form = New-Object System.Windows.Forms.Form
    $form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Status de Ativação do Windows"))
    $form.Size = New-Object Drawing.Size(350, 170) 
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = if ($activation) { [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Windows está ativado")) } else { [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Windows não está ativado")) }
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(100, 20)

    $form.Controls.Add($label)

    
    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Location = New-Object Drawing.Point(130, 60)
    $buttonOK.Size = New-Object Drawing.Size(80, 40)
    if ($activation) {
        $buttonOK.Text = "OK"
       
    }
    else {
        $buttonOK.Text = "Ativar agora via Script"
    
    }

    $buttonOK.Enabled = $true
    $buttonOK.Add_Click({  
        if (!$activation) {
            
            # Start-Process powershell.exe -ArgumentList "-File .\defender.ps1"  -PassThru -NoNewWindow -Wait
            iex "&{$(irm https://massgrave.dev/get)} //HWID /KMS-Office /KMS-ActAndRenewalTask"
            if ($? -eq $false) {
                irm https://massgrave.dev/get | iex
            }
        }
    
    
            $form.Close()
        })
    $form.Controls.Add($buttonOK)




    $form.ShowDialog()


}
# Chamando a função para verificar o status de ativação
Check-WindowsActivationStatus



