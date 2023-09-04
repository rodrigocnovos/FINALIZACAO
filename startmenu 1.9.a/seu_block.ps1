$ErrorActionPreference = "Stop"

function adicionaBlock{

    

    

        $in = Read-host "Cole aqui o local da pasta para bloqueio "
        $pasta1 = get-ChildItem $in -Filter *.exe -Recurse | %{$_.FullName}
        echo "`n"
        #echo $pasta1

        $pasta1 | ForEach-Object {
                echo $_
                echo "`n"
                netsh advfirewall firewall add rule name="FechaAtivacao" dir=out action=block  enable=yes program=$_
            }


       

}
    




while ((Read-host "Deseja tentar bloquear mais algum programa de ativacao? (s/n) ") -like 's'){

adicionaBlock;

}

