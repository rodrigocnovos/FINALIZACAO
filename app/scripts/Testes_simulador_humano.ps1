param(
    [switch]$SkipRestart,
    [switch]$AutoBoot
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:YoutubeWindowHandle = [IntPtr]::Zero

if (-not ("Win32Functions.WindowActivator" -as [type])) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    
    namespace Win32Functions {
        public static class WindowActivator {
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);

            [DllImport("user32.dll")]
            public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

            [DllImport("kernel32.dll")]
            public static extern IntPtr GetConsoleWindow();

            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
    }
"@
}

# Forçar visibilidade da janela do console se existir (ajuda quando chamado pelo runner oculto)
$consoleHandle = [Win32Functions.WindowActivator]::GetConsoleWindow()
if ($consoleHandle -ne [IntPtr]::Zero) {
    [Win32Functions.WindowActivator]::ShowWindow($consoleHandle, 5) # SW_SHOW
    [Win32Functions.WindowActivator]::SetForegroundWindow($consoleHandle) | Out-Null
}

if (-not ("Win32Functions.InputSimulator" -as [type])) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    namespace Win32Functions {
        public struct RECT
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }

        public static class InputSimulator
        {
            [DllImport("user32.dll")]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [DllImport("user32.dll")]
            public static extern bool SetCursorPos(int X, int Y);

            [DllImport("user32.dll")]
            public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);
        }
    }
"@
}

# Obter o diretório atual do script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir
$assetsPath = Join-Path $appRoot "assets\Arquivos"
$softwarePath = Join-Path $appRoot "softwares"
$unpackInstallersPath = Join-Path $softwarePath "unpack_installers"
$prime95ArchivePath = Join-Path $softwarePath "p95v3019b20.win64.zip"
$prime95ExtractPath = Join-Path $unpackInstallersPath "prime95"
$prime95Executable = Join-Path $prime95ExtractPath "prime95.exe"
$installBootLoopScript = Join-Path $scriptDir "install_human_test_boot_loop.ps1"

function Set-ProcessWindowToForeground {
    param(
        [string]$ProcessName,
        [int]$RetryCount = 10,
        [int]$RetryDelayMs = 500,
        [int]$nCmdShow = 9,
        [IntPtr]$ExcludeHandle = [IntPtr]::Zero
    )

    for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
        $windowProcess = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object { 
            $_.MainWindowHandle -ne 0 -and 
            ($ExcludeHandle -eq [IntPtr]::Zero -or $_.MainWindowHandle -ne $ExcludeHandle) 
        } |
        Select-Object -First 1

        if ($windowProcess) {
            # Truque para burlar restrição de SetForegroundWindow quando o chamador está em segundo plano
            try { [System.Windows.Forms.SendKeys]::SendWait("%") } catch {}
            [Win32Functions.WindowActivator]::ShowWindowAsync([IntPtr]$windowProcess.MainWindowHandle, $nCmdShow) | Out-Null
            [Win32Functions.WindowActivator]::SetForegroundWindow([IntPtr]$windowProcess.MainWindowHandle) | Out-Null
            return $true
        }

        Start-Sleep -Milliseconds $RetryDelayMs
    }

    return $false
}

function Set-WindowHandleToForeground {
    param(
        [IntPtr]$Handle
    )

    if ($Handle -eq [IntPtr]::Zero) {
        return $false
    }

    [Win32Functions.WindowActivator]::ShowWindowAsync($Handle, 9) | Out-Null
    [Win32Functions.WindowActivator]::SetForegroundWindow($Handle) | Out-Null
    return $true
}

function Minimize-WindowHandle {
    param(
        [IntPtr]$Handle
    )

    if ($Handle -eq [IntPtr]::Zero) {
        return $false
    }

    [Win32Functions.WindowActivator]::ShowWindow($Handle, 6) | Out-Null # SW_MINIMIZE
    return $true
}

function Start-WindowsApp {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments = @(),
        [int]$PauseSeconds = 3
    )

    try {
        Write-Output "Abrindo aplicativo do Windows: $Name"
        if ($Arguments.Count -gt 0) {
            Start-Process -FilePath $FilePath -ArgumentList $Arguments | Out-Null
        }
        else {
            Start-Process -FilePath $FilePath | Out-Null
        }
        Start-Sleep -Seconds $PauseSeconds
    }
    catch {
        Write-Warning "Falha ao abrir ${Name}: $($_.Exception.Message)"
    }
}

function Get-PreferredBrowserPath {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }

        $appPathRegistry = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$candidate"
        $appPath = (Get-ItemProperty -Path $appPathRegistry -ErrorAction SilentlyContinue).'(default)'
        if ($appPath -and (Test-Path -LiteralPath $appPath)) {
            return $appPath
        }

        $commonPaths = switch -Regex ($candidate) {
            '^msedge(\.exe)?$' {
                @(
                    (Join-Path $env:ProgramFiles "Microsoft\Edge\Application\msedge.exe"),
                    (Join-Path ${env:ProgramFiles(x86)} "Microsoft\Edge\Application\msedge.exe"),
                    (Join-Path $env:LocalAppData "Microsoft\Edge\Application\msedge.exe")
                )
                break
            }
            '^chrome(\.exe)?$' {
                @(
                    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
                    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
                    (Join-Path $env:LocalAppData "Google\Chrome\Application\chrome.exe")
                )
                break
            }
            default { @() }
        }

        foreach ($path in $commonPaths) {
            if ($path -and (Test-Path -LiteralPath $path)) {
                return $path
            }
        }
    }

    return $null
}

function Invoke-BrowserFeedScroll {
    param(
        [int]$ScrollCount = 3,
        [string]$BrowserProcessName,
        [IntPtr]$ExcludeHandle = [IntPtr]::Zero
    )

    if ($BrowserProcessName) {
        # Garante que o navegador esteja em primeiro plano
        $windowProcess = Get-Process -Name $BrowserProcessName -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowHandle -ne 0 } |
            Select-Object -First 1

        if ($windowProcess) {
            Set-ProcessWindowToForeground -ProcessName $BrowserProcessName -RetryCount 5 -RetryDelayMs 300 -ExcludeHandle $ExcludeHandle | Out-Null
            
            # Centralizar o mouse no navegador para garantir que o scroll funcione na janela correta
            $rect = New-Object Win32Functions.RECT
            if ([Win32Functions.InputSimulator]::GetWindowRect([IntPtr]$windowProcess.MainWindowHandle, [ref]$rect)) {
                $centerX = [int]($rect.Left + ($rect.Right - $rect.Left) / 2)
                $centerY = [int]($rect.Top + ($rect.Bottom - $rect.Top) / 2)
                [Win32Functions.InputSimulator]::SetCursorPos($centerX, $centerY)
                Start-Sleep -Milliseconds 200
            }
        }
        Start-Sleep -Milliseconds 500
    }

    Write-Output "Simulando rolagem de página..."
    
    for ($scrollIndex = 0; $scrollIndex -lt $ScrollCount; $scrollIndex++) {
        # Usar mouse_event para scroll (mais robusto que SendKeys em alguns sites)
        for ($s = 0; $s -lt 8; $s++) {
            [Win32Functions.InputSimulator]::mouse_event(0x0800, 0, 0, -120, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 50
        }
        
        # Complemento com PageDown/Down para garantir movimento
        [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
        
        # Pequena variação humana com setas para baixo
        $extraDowns = Get-Random -Minimum 1 -Maximum 3
        for ($i = 0; $i -lt $extraDowns; $i++) {
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
            [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
        }
        
        Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 4)
    }
}

function Set-ClipboardTextSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    try {
        Set-Clipboard -Value $Text
        return $true
    }
    catch {
        try {
            [System.Windows.Forms.Clipboard]::SetText($Text)
            return $true
        }
        catch {
            Write-Warning "Falha ao copiar URL para a area de transferencia: $($_.Exception.Message)"
            return $false
        }
    }
}

function Open-BrowserUrlInActiveWindow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [string]$BrowserProcessName,
        [IntPtr]$ExcludeHandle = [IntPtr]::Zero
    )

    if ($BrowserProcessName) {
        # Tenta encontrar um processo que tenha janela e não seja o excluído
        $targetHandle = [IntPtr]::Zero
        $attempts = 0
        while ($targetHandle -eq [IntPtr]::Zero -and $attempts -lt 20) {
            $procs = Get-Process -Name $BrowserProcessName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
            foreach ($p in $procs) {
                if ($ExcludeHandle -eq [IntPtr]::Zero -or $p.MainWindowHandle -ne $ExcludeHandle) {
                    $targetHandle = $p.MainWindowHandle
                    break
                }
            }
            if ($targetHandle -eq [IntPtr]::Zero) {
                Start-Sleep -Milliseconds 300
                $attempts++
            }
        }

        if ($targetHandle -ne [IntPtr]::Zero) {
            [Win32Functions.WindowActivator]::ShowWindowAsync($targetHandle, 9) | Out-Null
            [Win32Functions.WindowActivator]::SetForegroundWindow($targetHandle) | Out-Null
        }
    }

    if (-not (Set-ClipboardTextSafe -Text $Url)) {
        return $false
    }

    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("^{l}")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("^v")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    return $true
}

function Confirm-Prime95TortureDialog {
    param(
        [int]$ProcessId,
        [int]$RetryCount = 20,
        [int]$RetryDelayMs = 500
    )

    Add-Type -AssemblyName UIAutomationClient
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $processCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ProcessIdProperty,
        $ProcessId
    )
    $buttonCondition = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
    )

    for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
        Start-Sleep -Milliseconds $RetryDelayMs

        $window = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $processCondition)
        if (-not $window) {
            continue
        }

        if ($window.Current.Name -notmatch "Torture") {
            continue
        }

        Set-WindowHandleToForeground -Handle ([IntPtr]$window.Current.NativeWindowHandle) | Out-Null
        $buttons = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)

        foreach ($button in $buttons) {
            if ($button.Current.Name -match "^OK$") {
                $invokePattern = $null
                if ($button.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$invokePattern)) {
                    $invokePattern.Invoke()
                    return $true
                }
            }
        }

        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        return $true
    }

    return $false
}

function Ensure-HumanTestBootLoop {
    if (-not (Test-Path -LiteralPath $installBootLoopScript)) {
        Write-Warning "Instalador do loop de boot nao encontrado em $installBootLoopScript"
        return
    }

    try {
        $installOutput = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installBootLoopScript 2>&1
        $installText = ($installOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine

        if ($installText) {
            Write-Output $installText
        }

        if ($installText -match "Launcher instalado em:") {
            Show-HumanTestLoopInfoForm
        }
    }
    catch {
        Write-Warning "Falha ao instalar o loop de boot do teste humano: $($_.Exception.Message)"
    }
}

function Show-HumanTestStartConfirmationForm {
    $confirmation = [PSCustomObject]@{
        Continue = $false
    }

    $form = New-Object Windows.Forms.Form
    $form.Text = "Microfacil Finalizacao - Confirmacao do Loop de Teste Humano"
    $form.Size = New-Object Drawing.Size(760, 560)
    $form.StartPosition = "CenterScreen"
    $form.AutoScroll = $false
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.FormBorderStyle = "FixedDialog"
    $form.TopMost = $true

    $titleLabel = New-Object Windows.Forms.Label
    $titleLabel.Text = "Confirma iniciar o loop automatico do teste humano?"
    $titleLabel.Location = New-Object Drawing.Point(20, 20)
    $titleLabel.Size = New-Object Drawing.Size(680, 30)
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($titleLabel)

    $descriptionLabel = New-Object Windows.Forms.Label
    $descriptionLabel.Text = "Ao continuar, este script instala o inicio automatico do teste humano e executa o ciclo atual agora.`r`n`r`nDurante cada ciclo, a maquina vai:`r`n- abrir YouTube e navegar por varios sites em abas e tela cheia`r`n- abrir apps do Windows como Calculadora, Bloco de Notas, Paint, WordPad, CMD, PowerShell, Gerenciador de Tarefas, Painel de Controle, Mapa de Caracteres e Ferramenta de Captura`r`n- abrir Excel, PowerPoint, Explorer e Word com automacao de uso`r`n- finalizar com carga forte de CPU no Prime95 por 5 minutos`r`n`r`nDepois que o Prime95 terminar, o computador sera reiniciado para repetir o teste.`r`nNos proximos boots, antes do teste iniciar, aparecera uma janela com contagem de 10 segundos.`r`nClique em 'Remover' nessa janela para apagar o inicio automatico e encerrar o loop."
    $descriptionLabel.Location = New-Object Drawing.Point(20, 70)
    $descriptionLabel.Size = New-Object Drawing.Size(700, 220)
    $descriptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.Controls.Add($descriptionLabel)

    $alertPanel = New-Object Windows.Forms.Panel
    $alertPanel.Location = New-Object Drawing.Point(20, 300)
    $alertPanel.Size = New-Object Drawing.Size(700, 110)
    $alertPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $alertPanel.BackColor = [System.Drawing.Color]::FromArgb(255, 249, 230)
    $form.Controls.Add($alertPanel)

    $alertIcon = New-Object Windows.Forms.PictureBox
    $alertIcon.Location = New-Object Drawing.Point(14, 18)
    $alertIcon.Size = New-Object Drawing.Size(32, 32)
    $alertIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $alertIcon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
    $alertPanel.Controls.Add($alertIcon)

    $alertTitleLabel = New-Object Windows.Forms.Label
    $alertTitleLabel.Text = "Atencao antes de iniciar"
    $alertTitleLabel.Location = New-Object Drawing.Point(58, 14)
    $alertTitleLabel.Size = New-Object Drawing.Size(620, 24)
    $alertTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $alertPanel.Controls.Add($alertTitleLabel)

    $alertBodyLabel = New-Object Windows.Forms.Label
    $alertBodyLabel.Text = "Remova a senha do usuario do Windows antes de iniciar o loop.`r`nSe a maquina pedir senha na tela de login, o teste sera interrompido ate que alguem digite a senha manualmente."
    $alertBodyLabel.Location = New-Object Drawing.Point(58, 42)
    $alertBodyLabel.Size = New-Object Drawing.Size(620, 52)
    $alertBodyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
    $alertPanel.Controls.Add($alertBodyLabel)

    $noteLabel = New-Object Windows.Forms.Label
    $noteLabel.Text = "Cancelar fecha esta tela e nao inicia o teste."
    $noteLabel.Location = New-Object Drawing.Point(20, 425)
    $noteLabel.Size = New-Object Drawing.Size(420, 24)
    $noteLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
    $form.Controls.Add($noteLabel)

    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Location = New-Object Drawing.Point(500, 455)
    $buttonOK.Size = New-Object Drawing.Size(90, 32)
    $buttonOK.Text = "OK"
    $buttonOK.Add_Click({
            $confirmation.Continue = $true
            $form.Close()
        })
    $form.Controls.Add($buttonOK)

    $buttonCancel = New-Object Windows.Forms.Button
    $buttonCancel.Location = New-Object Drawing.Point(605, 455)
    $buttonCancel.Size = New-Object Drawing.Size(90, 32)
    $buttonCancel.Text = "Cancelar"
    $buttonCancel.Add_Click({
            $form.Close()
        })
    $form.Controls.Add($buttonCancel)

    $form.AcceptButton = $buttonOK
    $form.CancelButton = $buttonCancel

    $timerState = [PSCustomObject]@{ Seconds = 120 }
    $buttonOK.Text = "OK ($($timerState.Seconds))"

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
            $timerState.Seconds--
            if ($timerState.Seconds -le 0) {
                $timer.Stop()
                $confirmation.Continue = $true
                $form.Close()
                return
            }
            $buttonOK.Text = "OK ($($timerState.Seconds))"
            $buttonOK.Refresh()
        })

    $form.Add_Shown({
            [Win32Functions.WindowActivator]::ShowWindowAsync($form.Handle, 9) | Out-Null
            [Win32Functions.WindowActivator]::SetForegroundWindow($form.Handle) | Out-Null
            $form.Activate()
            $form.BringToFront()
            $buttonOK.Focus()
            $timer.Start()
        })

    $form.Add_FormClosed({
            $timer.Stop()
        })

    $form.ShowDialog() | Out-Null

    return $confirmation.Continue
}

function Show-HumanTestLoopInfoForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "FINALIZACAO - Loop de Teste Humano"
    $form.Size = New-Object System.Drawing.Size(560, 260)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true
    $form.BackColor = [System.Drawing.Color]::WhiteSmoke

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Loop automatico configurado"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 18)
    $titleLabel.Size = New-Object System.Drawing.Size(500, 28)
    $form.Controls.Add($titleLabel)

    $bodyLabel = New-Object System.Windows.Forms.Label
    $bodyLabel.Text = "Este teste humano agora sera executado automaticamente a cada reinicializacao.`r`n`r`nNo proximo boot, antes do teste iniciar, aparecera uma janela com contagem de 10 segundos.`r`nClique em 'Remover' nessa janela para apagar o inicio automatico e parar o loop.`r`nSe nao clicar, o teste continua normalmente."
    $bodyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $bodyLabel.Location = New-Object System.Drawing.Point(20, 58)
    $bodyLabel.Size = New-Object System.Drawing.Size(510, 120)
    $form.Controls.Add($bodyLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $okButton.Size = New-Object System.Drawing.Size(110, 34)
    $okButton.Location = New-Object System.Drawing.Point(210, 185)
    $okButton.Add_Click({ $form.Close() })
    $form.Controls.Add($okButton)

    $timerState = [PSCustomObject]@{ Seconds = 10 }
    $okButton.Text = "OK ($($timerState.Seconds))"

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
            $timerState.Seconds--
            if ($timerState.Seconds -le 0) {
                $timer.Stop()
                $form.Close()
                return
            }
            $okButton.Text = "OK ($($timerState.Seconds))"
            $okButton.Refresh()
        })

    $form.Add_Shown({
            [Win32Functions.WindowActivator]::ShowWindowAsync($form.Handle, 9) | Out-Null
            [Win32Functions.WindowActivator]::SetForegroundWindow($form.Handle) | Out-Null
            $form.Activate()
            $form.BringToFront()
            $okButton.Focus()
            $timer.Start()
        })

    $form.Add_FormClosed({
            $timer.Stop()
        })

    $form.ShowDialog() | Out-Null
}

Write-Output "Script PowerShell para abrir programas e simular comportamento humano (Teste de Estresse/Uso)"
if (-not $AutoBoot -and -not (Show-HumanTestStartConfirmationForm)) {
    Write-Output "Execucao cancelada pelo usuario antes do inicio do teste."
    return
}
Ensure-HumanTestBootLoop

# Selecionar um unico navegador para toda a etapa web do teste
$browserPath = Get-PreferredBrowserPath -Candidates @("msedge.exe", "chrome.exe")
$browserProcessName = if ($browserPath) { [System.IO.Path]::GetFileNameWithoutExtension($browserPath) } else { $null }

# Abrir YouTube em janela dedicada dentro do navegador escolhido
$youtubeUrl = "https://www.youtube.com/watch?v=36YnV9STBqc&autoplay=1"

if ($browserPath) {
    if ($browserProcessName) {
        Write-Output "Acessando YouTube em nova janela: $youtubeUrl"
        Start-Process -FilePath $browserPath -ArgumentList @("--new-window", $youtubeUrl) | Out-Null
        Write-Output "Aguardando carregamento da pagina do YouTube por 10 segundos..."
        Start-Sleep -Seconds 10

        Write-Output "Maximizando a janela do YouTube temporariamente..."
        if (Set-ProcessWindowToForeground -ProcessName $browserProcessName -nCmdShow 3 -RetryCount 20 -RetryDelayMs 500) {
            $windowProcess = Get-Process -Name $browserProcessName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
            if ($windowProcess) {
                $global:YoutubeWindowHandle = [IntPtr]$windowProcess.MainWindowHandle
                Start-Sleep -Seconds 5
                Write-Output "Minimizando a janela do YouTube para prosseguir com o teste..."
                Minimize-WindowHandle -Handle $global:YoutubeWindowHandle | Out-Null
            }
        }
    }
}
else {
    Write-Warning "Nenhum navegador compativel foi encontrado para abrir o YouTube."
}
Start-Sleep -Seconds 4

# Abrir Navegador e acessar URLs com pausas aleatórias
$urls = @(
    "https://www.uol.com.br/",
    "https://g1.globo.com/",
    "https://www.terra.com.br/",
    "https://noticias.uol.com.br/",
    "https://www.estadao.com.br/",
    "https://www.cnnbrasil.com.br/",
    "https://www.metropoles.com/",
    "https://github.com/",
    "https://www.reddit.com/",
    "https://www.amazon.com.br/",
    "https://www.mercadolivre.com.br/",
    "https://shopee.com.br/",
    "https://www.magazineluiza.com.br/",
    "https://www.americanas.com.br/",
    "https://www.casasbahia.com.br/",
    "https://www.kabum.com.br/",
    "https://www.globo.com/",
    "https://www.tecmundo.com.br/",
    "https://www.linkedin.com/",
    "https://www.omelete.com.br/",
    "https://www.adrenaline.com.br/",
    "https://www.tudocelular.com/",
    "https://www.infomoney.com.br/",
    "https://br.investing.com/",
    "https://stackoverflow.com/"
)

for ($index = 0; $index -lt $urls.Count; $index++) {
    $url = $urls[$index]
    Write-Output "Acessando: $url"

    if (-not $browserPath) {
        Write-Warning "Ignorando navegacao web porque nenhum navegador compativel foi encontrado."
        break
    }

    if ($index -eq 0) {
        Start-Process -FilePath $browserPath -ArgumentList @("--new-window", $url) | Out-Null
        if ($browserProcessName -and (Set-ProcessWindowToForeground -ProcessName $browserProcessName -RetryCount 20 -RetryDelayMs 500 -ExcludeHandle $global:YoutubeWindowHandle)) {
            Start-Sleep -Seconds 1
            [System.Windows.Forms.SendKeys]::SendWait("{F11}")
        }
    }
    else {
        if (-not (Open-BrowserUrlInActiveWindow -Url $url -BrowserProcessName $browserProcessName -ExcludeHandle $global:YoutubeWindowHandle)) {
            Write-Warning "Falha ao navegar para $url na janela ativa do navegador."
            continue
        }
    }

    Start-Sleep -Seconds (Get-Random -Minimum 6 -Maximum 10)
    if ($browserProcessName) {
        Set-ProcessWindowToForeground -ProcessName $browserProcessName -RetryCount 10 -RetryDelayMs 300 -ExcludeHandle $global:YoutubeWindowHandle | Out-Null
    }
    Invoke-BrowserFeedScroll -ScrollCount 3 -BrowserProcessName $browserProcessName -ExcludeHandle $global:YoutubeWindowHandle
}

# ==========================================
# APPS DO WINDOWS - Abertura Sequencial
# ==========================================
$windowsApps = @(
    @{ Name = "Calculadora"; FilePath = "calc.exe" },
    @{ Name = "Bloco de Notas"; FilePath = "notepad.exe" },
    @{ Name = "Paint"; FilePath = "mspaint.exe" },
    @{ Name = "WordPad"; FilePath = "write.exe" },
    @{ Name = "Prompt de Comando"; FilePath = "cmd.exe" },
    @{ Name = "PowerShell"; FilePath = "powershell.exe" },
    @{ Name = "Gerenciador de Tarefas"; FilePath = "taskmgr.exe" },
    @{ Name = "Painel de Controle"; FilePath = "control.exe" },
    @{ Name = "Mapa de Caracteres"; FilePath = "charmap.exe" },
    @{ Name = "Ferramenta de Captura"; FilePath = "SnippingTool.exe" }
)

foreach ($app in $windowsApps) {
    Start-WindowsApp -Name $app.Name -FilePath $app.FilePath -PauseSeconds (Get-Random -Minimum 3 -Maximum 6)
}

# ==========================================
# EXCEL - Automação e Digitação Aleatória
# ==========================================
Write-Output "Iniciando Microsoft Excel e gerando planilha aleatória..."
try {
    $Excel = New-Object -ComObject Excel.Application
    $Excel.Visible = $true
    $Workbook = $Excel.Workbooks.Add()
    $Worksheet = $Workbook.Worksheets.Item(1)

    # Obter a janela do Excel e ativar
    $excelWindow = Get-Process excel | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($excelWindow) {
        Set-WindowHandleToForeground -Handle ([IntPtr]$excelWindow.MainWindowHandle) | Out-Null
    }

    Start-Sleep -Seconds 2

    # Digitar valores com formulas matematicas pesadas embaralhadas
    for ($i = 1; $i -le 50; $i++) {
        $Worksheet.Cells.Item($i, 1).Value2 = Get-Random -Minimum 10 -Maximum 999
        $Worksheet.Cells.Item($i, 2).Value2 = Get-Random -Minimum 1 -Maximum 99
        # Expressao matematica mais robusta misturando SOMA, LOG, RAIZ.
        $formula = "=SUM(`$A`$1:`$A`$50)*LOG(B$i)+SQRT(A$i)"
        $Worksheet.Cells.Item($i, 3).Formula = $formula
        
        Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 400)
    }
}
catch {
    Write-Warning "Falha ao simular o Excel. O programa está instalado?"
}

# ==========================================
# POWERPOINT - Abertura de Slides
# ==========================================
Write-Output "Iniciando PowerPoint..."
$SlideFilePath = Join-Path $assetsPath "slide.pptx"

if (-Not (Test-Path -Path $SlideFilePath)) {
    Write-Warning "O arquivo 'slide.pptx' não foi encontrado em $SlideFilePath."
}
else {
    try {
        try { $Excel.WindowState = -4140 } catch {}

        $PowerPoint = New-Object -ComObject PowerPoint.Application
        # Usa -1 ao inves do MsoTriState para evitar erros de cast em Office desatualizado
        $PowerPoint.Visible = -1
        $Presentation = $PowerPoint.Presentations.Open($SlideFilePath)
        $SlideShow = $Presentation.SlideShowSettings.Run()
        $shell = New-Object -ComObject WScript.Shell

        for ($attempt = 0; $attempt -lt 20; $attempt++) {
            Start-Sleep -Milliseconds 500

            try {
                $slideShowWindow = $PowerPoint.SlideShowWindows.Item(1)
                if ($slideShowWindow -and $slideShowWindow.HWND) {
                    Set-WindowHandleToForeground -Handle ([IntPtr]$slideShowWindow.HWND) | Out-Null
                    break
                }
            }
            catch { }
        }

        Start-Sleep -Seconds (Get-Random -Minimum 10 -Maximum 20)
        $Presentation.Close()

        $powerPointProcess = Get-Process -Name "powerpnt" -ErrorAction SilentlyContinue
        if ($powerPointProcess) {
            Stop-Process -Id $powerPointProcess.Id -Force
            Write-Output "PowerPoint encerrado."
        }
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($SlideShow) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Presentation) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($PowerPoint) | Out-Null
    }
    catch {
        Write-Warning "Falha ao manipular a apresentação do PowerPoint."
    }
}

# Abrir Windows Explorer de forma aleatória
Start-Process "explorer.exe"
Start-Sleep -Seconds (Get-Random -Minimum 3 -Maximum 6)

# ==========================================
# WORD - Digitação Humana Aleatória
# ==========================================
Write-Output "Iniciando Microsoft Word..."
try {
    $Word = New-Object -ComObject Word.Application
    $Word.Visible = $true
    $Document = $Word.Documents.Add()
    $Document.Activate()

    $wordWindow = Get-Process winword | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if ($wordWindow) {
        Set-WindowHandleToForeground -Handle ([IntPtr]$wordWindow.MainWindowHandle) | Out-Null
    }
    Start-Sleep -Seconds 2

    $texto = "Este é um documento de teste MICROFACIL de auto-digitação no Word! Teste de estresse com atrasos aleatorios para avaliar a estabilidade e a responsividade do sistema durante picos e pausas..."
    
    foreach ($char in $texto.ToCharArray()) {
        [System.Windows.Forms.SendKeys]::SendWait($char)
        # Randomidade extrema na digitação humana
        if ((Get-Random -Minimum 1 -Maximum 100) -gt 90) {
            Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 800)
        }
        else {
            Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 80)
        }
    }
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
}
catch {
    Write-Warning "Falha ao simular o Word."
}

Write-Output "Teste de estresse humanoide concluído! Fechando as janelas geradas..."
Write-Output "Preparando Prime95 para carga final de CPU..."

try {
    if (-not (Test-Path -LiteralPath $prime95Executable)) {
        if (-not (Test-Path -LiteralPath $prime95ArchivePath)) {
            throw "Arquivo compactado do Prime95 nao encontrado em $prime95ArchivePath."
        }

        New-Item -ItemType Directory -Path $prime95ExtractPath -Force | Out-Null
        Expand-Archive -LiteralPath $prime95ArchivePath -DestinationPath $prime95ExtractPath -Force
    }

    Write-Output "Executando Prime95 por 5 minutos..."
    $prime95Process = Start-Process -FilePath $prime95Executable -ArgumentList "-t" -WorkingDirectory $prime95ExtractPath -PassThru
    Confirm-Prime95TortureDialog -ProcessId $prime95Process.Id | Out-Null
    Start-Sleep -Seconds 300

    if ($prime95Process -and -not $prime95Process.HasExited) {
        Stop-Process -Id $prime95Process.Id -Force -ErrorAction SilentlyContinue
        Write-Output "Prime95 encerrado apos 5 minutos."
    }
}
catch {
    Write-Warning "Falha ao executar o Prime95: $($_.Exception.Message)"
}

# ==========================================
# TAREFAS DE LIMPEZA E ENCERRAMENTO
# ==========================================
try { $Excel.Quit() } catch {}
try { $Word.Quit() } catch {}

$processToClose = @("chrome", "msedge", "powerpnt", "excel", "winword", "prime95", "notepad", "mspaint", "write", "cmd", "powershell", "taskmgr", "SnippingTool", "calc")
foreach ($proc in $processToClose) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Fechar gentilmente janelas do Explorer
try {
    $shell = New-Object -ComObject Shell.Application
    if ($shell) {
        $shell.Windows() | ForEach-Object {
            if ($_.Name -match "Explorer" -or $_.Name -match "Explorador") {
                $_.Quit()
            }
        }
    }
}
catch { }

Write-Output "Todos os artefatos de teste foram encerrados e o sistema está limpo."

if (-not $SkipRestart) {
    Write-Output "Reiniciando o computador em 10 segundos..."
    shutdown.exe /r /t 10 /f /c "FINALIZACAO - reinicio automatico do ciclo Testes_simulador_humano"
}
else {
    Write-Output "Reinicio automatico ignorado."
}
