FINALIZACAO
├── FinalizaInstalacao.bat
└── app
    ├── bin
    │   └── elevate.exe
    ├── config
    │   ├── launcher.version
    │   └── branch_update.ini (opcional, local)
    ├── scripts
    │   ├── super.bat
    │   ├── ENDER.ps1
    │   ├── runner.ps1
    │   ├── update_script.ps1
    │   └── demais scripts .ps1/.vbs
    ├── assets
    │   ├── Desktop
    │   ├── ico
    │   ├── wallpaper
    │   ├── Arquivos
    │   ├── win11_files
    │   └── arquivos de apoio (.xml, .reg, .bmp)
    ├── softwares
    │   └── instaladores e PortableGit
    └── data
        └── arquivos auxiliares (.txt)

Regras:
- `app/scripts/super.bat` e o launcher principal.
- `FinalizaInstalacao.bat` e o atalho de elevacao.
- O update consulta `app/config/launcher.version`.
- Os scripts internos devem resolver caminhos a partir de `app/scripts`.
