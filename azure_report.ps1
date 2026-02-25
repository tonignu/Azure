<#
.SYNOPSIS
Azure Critical Services Production Report

.DESCRIPTION
Genera un reporte completo de:
- Identidad y suscripción
- Virtual Machines
- Storage Accounts
- Discos administrados sin asociar
- Usuarios y roles (Microsoft Entra ID)

Requiere módulo Az instalado.
#>

param(
    [string]$OutputPath = ".\AzureReports"
)

# =========================
# VALIDACIONES INICIALES
# =========================

if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Error "El módulo Az no está instalado. Ejecuta: Install-Module Az -Scope CurrentUser"
    exit
}

try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "No hay sesión activa. Iniciando login..."
        Connect-AzAccount -ErrorAction Stop
        $context = Get-AzContext
    }
}
catch {
    Write-Error "No se pudo autenticar en Azure."
    exit
}

# Crear carpeta de salida
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFolder = "$OutputPath\AzureReport_$timestamp"
New-Item -ItemType Directory -Path $ReportFolder -Force | Out-Null

Write-Host "Generando reporte en: $ReportFolder"

# =========================
# 1. IDENTIDAD
# =========================

$identityReport = [PSCustomObject]@{
    SubscriptionName = $context.Subscription.Name
    SubscriptionId   = $context.Subscription.Id
    TenantId         = $context.Tenant.Id
    Account          = $context.Account.Id
    AccountType      = $context.Account.Type
}

$identityReport | Export-Csv "$ReportFolder\Identity.csv" -NoTypeInformation

# =========================
# 2. VIRTUAL MACHINES
# =========================

$vms = Get-AzVM -Status

$vmReport = foreach ($vm in $vms) {

    $nic = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine.Id -eq $vm.Id }
    $publicIps = foreach ($ipConfig in $nic.IpConfigurations) {
        if ($ipConfig.PublicIpAddress) {
            (Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id).IpAddress
        }
    }

    [PSCustomObject]@{
        VMName        = $vm.Name
        ResourceGroup = $vm.ResourceGroupName
        Size          = $vm.HardwareProfile.VmSize
        PowerState    = ($vm.Statuses | Where-Object Code -like "PowerState/*").DisplayStatus
        PublicIP      = ($publicIps -join ", ")
    }
}

$vmReport | Export-Csv "$ReportFolder\VirtualMachines.csv" -NoTypeInformation

# =========================
# 3. STORAGE ACCOUNTS
# =========================

$storageReport = Get-AzStorageAccount | Select-Object `
    StorageAccountName,
    ResourceGroupName,
    Location,
    SkuName,
    Kind,
    AccessTier

$storageReport | Export-Csv "$ReportFolder\StorageAccounts.csv" -NoTypeInformation

# =========================
# 4. COST OPTIMIZATION
# =========================

$unattachedDisks = Get-AzDisk | Where-Object { -not $_.ManagedBy }

$diskReport = $unattachedDisks | Select-Object `
    Name,
    ResourceGroupName,
    Location,
    DiskSizeGB,
    Sku

$diskReport | Export-Csv "$ReportFolder\UnattachedDisks.csv" -NoTypeInformation

# =========================
# 5. SEGURIDAD - Microsoft Entra ID
# =========================

$userReport = Get-AzADUser | Select-Object `
    DisplayName,
    UserPrincipalName,
    AccountEnabled

$userReport | Export-Csv "$ReportFolder\EntraID_Users.csv" -NoTypeInformation

$roleReport = Get-AzRoleAssignment | Select-Object `
    DisplayName,
    RoleDefinitionName,
    Scope

$roleReport | Export-Csv "$ReportFolder\RBAC_Roles.csv" -NoTypeInformation

# =========================
# GENERAR REPORTE HTML CONSOLIDADO
# =========================

$fullReport = @()

$fullReport += "<h1>Azure Critical Services Report</h1>"
$fullReport += "<h3>Generated: $(Get-Date)</h3>"
$fullReport += "<h2>Identity</h2>"
$fullReport += ($identityReport | ConvertTo-Html -Fragment)
$fullReport += "<h2>Virtual Machines</h2>"
$fullReport += ($vmReport | ConvertTo-Html -Fragment)
$fullReport += "<h2>Storage Accounts</h2>"
$fullReport += ($storageReport | ConvertTo-Html -Fragment)
$fullReport += "<h2>Unattached Disks</h2>"
$fullReport += ($diskReport | ConvertTo-Html -Fragment)
$fullReport += "<h2>Entra ID Users</h2>"
$fullReport += ($userReport | ConvertTo-Html -Fragment)
$fullReport += "<h2>RBAC Roles</h2>"
$fullReport += ($roleReport | ConvertTo-Html -Fragment)

$fullReport | ConvertTo-Html | Out-File "$ReportFolder\Azure_Full_Report.html"

Write-Host "Reporte generado correctamente."
Write-Host "Archivos creados:"
Get-ChildItem $ReportFolder
