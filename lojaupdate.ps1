#Abrir a o windows update
control /name Microsoft.WindowsUpdate



# Obter a lista de aplicativos da Microsoft Store instalados
$storeApps = Get-AppxPackage -AllUsers | Where-Object { $_.IsFramework -eq $false }

# Para cada aplicativo, verificar e reinstalar se estiver desatualizado
$storeApps | ForEach-Object {
    $app = $_
    $currentVersion = $app.Version

    # Obter informações sobre o aplicativo da Microsoft Store
    $storeAppInfo = Get-AppxPackageManifest $app.PackageFamilyName
    $storeAppVersion = $storeAppInfo.Package.Identity.Version

    if ($storeAppVersion -gt $currentVersion) {
        Write-Host "O aplicativo $($app.Name) está desatualizado. Versão atual: $currentVersion, Nova versão: $storeAppVersion"

        # Desinstalar o aplicativo desatualizado
        Write-Host "Desinstalando $($app.Name)..."
        Remove-AppxPackage -Package $app.PackageFullName

        # Instalar a versão atualizada do aplicativo
        Write-Host "Instalando a versão atualizada de $($app.Name)..."
        $storeAppInfo.Package.InstallLocation | ForEach-Object {
            Add-AppxPackage -Path $_
        }
    } else {
        Write-Host "O aplicativo $($app.Name) está atualizado."
    }
}
