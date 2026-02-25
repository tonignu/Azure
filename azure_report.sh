#!/bin/bash

# ==========================================================
# Azure Critical Services Report
# ==========================================================
# Ejecuta comandos de Azure PowerShell (Az Module)
# ==========================================================

pwsh << 'EOF'

Write-Host "============================================="
Write-Host "AZURE CRITICAL SERVICES REPORT"
Write-Host "Generated on: $(Get-Date)"
Write-Host "============================================="

# ----------------------------------------------------------
# 1. IDENTIDAD
# ----------------------------------------------------------
Write-Host "`n========== IDENTITY =========="

$context = Get-AzContext
$subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id

Write-Host "Active Subscription:" $subscription.Name
Write-Host "Subscription ID:" $subscription.Id
Write-Host "Tenant ID:" $context.Tenant.Id
Write-Host "Account:" $context.Account.Id
Write-Host "Account Type:" $context.Account.Type


# ----------------------------------------------------------
# 2. VIRTUAL MACHINES
# ----------------------------------------------------------
Write-Host "`n========== VIRTUAL MACHINES =========="

$vms = Get-AzVM -Status

$vmReport = $vms | ForEach-Object {
    $publicIp = Get-AzPublicIpAddress | Where-Object {
        $_.IpConfiguration.Id -match $_.NetworkProfile.NetworkInterfaces.Id
    }

    [PSCustomObject]@{
        VMName       = $_.Name
        ResourceGroup= $_.ResourceGroupName
        Size         = $_.HardwareProfile.VmSize
        PowerState   = ($_.Statuses | Where-Object Code -like "PowerState/*").DisplayStatus
        PublicIP     = ($publicIp.IpAddress -join ",")
    }
}

$vmReport | Format-Table -AutoSize


# ----------------------------------------------------------
# 3. STORAGE ACCOUNTS
# ----------------------------------------------------------
Write-Host "`n========== STORAGE ACCOUNTS =========="

$storageAccounts = Get-AzStorageAccount

$storageAccounts | Select-Object `
    StorageAccountName,
    ResourceGroupName,
    Location,
    SkuName,
    Kind,
    AccessTier |
    Format-Table -AutoSize


# ----------------------------------------------------------
# 4. COST OPTIMIZATION - UNATTACHED MANAGED DISKS
# ----------------------------------------------------------
Write-Host "`n========== UNATTACHED MANAGED DISKS =========="

$unattachedDisks = Get-AzDisk | Where-Object { -not $_.ManagedBy }

if ($unattachedDisks) {
    $unattachedDisks | Select-Object `
        Name,
        ResourceGroupName,
        Location,
        DiskSizeGB,
        Sku |
        Format-Table -AutoSize
} else {
    Write-Host "No unattached managed disks found."
}


# ----------------------------------------------------------
# 5. SEGURIDAD - MICROSOFT ENTRA ID (AZURE AD)
# ----------------------------------------------------------
Write-Host "`n========== MICROSOFT ENTRA ID - USERS & ROLES =========="

# Usuarios
Write-Host "`n--- Users ---"
Get-AzADUser | Select-Object `
    DisplayName,
    UserPrincipalName,
    AccountEnabled |
    Format-Table -AutoSize

# Role Assignments
Write-Host "`n--- Role Assignments ---"
Get-AzRoleAssignment | Select-Object `
    DisplayName,
    RoleDefinitionName,
    Scope |
    Format-Table -AutoSize


Write-Host "`n============================================="
Write-Host "END OF REPORT"
Write-Host "============================================="

EOF
