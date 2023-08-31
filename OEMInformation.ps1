
 # Caminho para o arquivo onde a variável será armazenada
 $caminhoArquivo = ".\tmp.txt"

 # Ler o valor da variável do arquivo
$tecOS = Get-Content -Path $caminhoArquivo


reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v Manufacturer /t REG_SZ /d "MICROFÁCIL INFORMÁTICA - $tecOS" /f
# reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v Model /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportHours /t REG_SZ /d "seg-sex: 8:00hs - 18:00hs/sab: 08:00 - 12:00" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportPhone /t REG_SZ /d "( 84 ) 99625-5676 ( 84 ) 3412-3863" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v SupportURL /t REG_SZ /d "https:\\www.microfacilrn.com.br" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v Logo /t REG_SZ /d "\\Users\\Public\\Pictures\\oemlogo.bmp" /f
