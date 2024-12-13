# Define o nome e caminho do arquivo de relatório
$outputPath = "$env:TEMP\battery-report.html"

# Gera o relatório de bateria no formato HTML
powercfg /batteryreport /output $outputPath

# Verifica se o relatório foi gerado com sucesso
if (Test-Path $outputPath) {
    Write-Host "Relatório de bateria gerado com sucesso: $outputPath"
    # Abre o relatório no navegador padrão
    Start-Process $outputPath
} else {
    Write-Host "Erro ao gerar o relatório de bateria. Verifique as permissões ou o comando."
}
