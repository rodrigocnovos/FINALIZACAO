@echo off

Rem @echo "Deseja adicionar algum programa para bloqueio extra?"
Rem set /p programa1="Copie e cole aqui o caminho da pasta para fechar no firewall: "


@echo "Deletando as chaves do registro do menu atual"
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount /f

@echo "Deletando comandos executados via EXECUTAR"
reg delete HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /f

@echo "Importando registros do menu"
reg import regMenu.reg
reg import icon_homeuser_computer.reg


@echo "Copiando o modelo padronizado do layout do menu"
copy DefaultLayouts.xml %LocalAppData%\Microsoft\Windows\Shell



@echo "Copiando os ìcones da área de trabalhao"

del %HOMEDRIVE%\Users\Public\Desktop /Q
del %userprofile%\desktop\*.* /Q
copy Desktop\*.* %userprofile%\desktop  /Y

setx curpath "%cd%"

elevate.exe -c call super.bat



@echo "Tudo Feito!"

timeout 4