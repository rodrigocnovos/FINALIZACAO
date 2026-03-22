Set objShell = CreateObject("WScript.Shell")

' Verifica se um argumento foi passado
If WScript.Arguments.Count = 0 Then
    WScript.Echo "Por favor, forneça o nome da janela como argumento."
    WScript.Quit
End If

' Obtém o nome da janela a partir dos argumentos de linha de comando
janela_alvo = WScript.Arguments(0)

' Ative a janela alvo pelo nome passado como argumento
objShell.AppActivate janela_alvo

' Aguarde um momento para a janela ganhar foco
WScript.Sleep 2000

' Envie três guias (Tab) antes de pressionar Enter
For i = 1 To 3
    objShell.SendKeys "{TAB}"
    WScript.Sleep 500  ' Ajuste o tempo de espera conforme necessário
Next

' Envie Enter
objShell.SendKeys "{ENTER}"
