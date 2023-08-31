Add-Type -TypeDefinition @'
using System;
using System.Windows.Forms;

public class MainForm : Form {
    private ProgressBar progressBar;
    
    public MainForm() {
        Text = "Barra de Progresso Marquee";
        Size = new System.Drawing.Size(300, 100);
        
        progressBar = new ProgressBar {
            Location = new System.Drawing.Point(20, 20),
            Size = new System.Drawing.Size(260, 20),
            Style = ProgressBarStyle.Marquee
        };
        Controls.Add(progressBar);
    }
}

Application.Run(new MainForm());
'@
