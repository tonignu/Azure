#!/bin/bash

# ==========================================================
# Azure Critical Services Report - Azure CLI Version
# ==========================================================

set -e

OUTPUT_PATH="./AzureReports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FOLDER="$OUTPUT_PATH/AzureReport_$TIMESTAMP"

mkdir -p "$REPORT_FOLDER"

echo "============================================="
echo "AZURE CRITICAL SERVICES REPORT"
echo "Generated on: $(date)"
echo "============================================="

# ----------------------------------------------------------
# VALIDACIONES
# ----------------------------------------------------------

if ! command -v az &> /dev/null
then
    echo "Azure CLI no está instalado."
    exit 1
fi

if ! az account show &> /dev/null
then
    echo "No hay sesión activa. Iniciando login..."
    az login
fi

# ----------------------------------------------------------
# 1. IDENTIDAD
# ----------------------------------------------------------

echo "Generando reporte de Identidad..."

az account show --query "{SubscriptionName:name, SubscriptionId:id, TenantId:tenantId, User:user.name}" \
    --output tsv > "$REPORT_FOLDER/Identity_raw.tsv"

echo "SubscriptionName,SubscriptionId,TenantId,User" > "$REPORT_FOLDER/Identity.csv"
cat "$REPORT_FOLDER/Identity_raw.tsv" | tr '\t' ',' >> "$REPORT_FOLDER/Identity.csv"
rm "$REPORT_FOLDER/Identity_raw.tsv"

# ----------------------------------------------------------
# 2. VIRTUAL MACHINES
# ----------------------------------------------------------

echo "Generando reporte de Virtual Machines..."

echo "VMName,ResourceGroup,Location,VMSize,PowerState,PublicIP" > "$REPORT_FOLDER/VirtualMachines.csv"

for vm in $(az vm list --query "[].id" -o tsv); do
    
    VM_NAME=$(az vm show --ids $vm --query "name" -o tsv)
    RG=$(az vm show --ids $vm --query "resourceGroup" -o tsv)
    LOCATION=$(az vm show --ids $vm --query "location" -o tsv)
    SIZE=$(az vm show --ids $vm --query "hardwareProfile.vmSize" -o tsv)
    POWER=$(az vm get-instance-view --ids $vm --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" -o tsv)

    PUBLIC_IP=$(az vm list-ip-addresses --ids $vm \
        --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv | paste -sd ";" -)

    echo "$VM_NAME,$RG,$LOCATION,$SIZE,$POWER,$PUBLIC_IP" >> "$REPORT_FOLDER/VirtualMachines.csv"
done

# ----------------------------------------------------------
# 3. STORAGE ACCOUNTS
# ----------------------------------------------------------

echo "Generando reporte de Storage Accounts..."

az storage account list \
    --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, SKU:sku.name, Kind:kind, AccessTier:accessTier}" \
    --output tsv > "$REPORT_FOLDER/Storage_raw.tsv"

echo "Name,ResourceGroup,Location,SKU,Kind,AccessTier" > "$REPORT_FOLDER/StorageAccounts.csv"
cat "$REPORT_FOLDER/Storage_raw.tsv" | tr '\t' ',' >> "$REPORT_FOLDER/StorageAccounts.csv"
rm "$REPORT_FOLDER/Storage_raw.tsv"

# ----------------------------------------------------------
# 4. COST OPTIMIZATION - UNATTACHED DISKS
# ----------------------------------------------------------

echo "Generando reporte de Discos Unattached..."

az disk list \
    --query "[?managedBy==null].{Name:name, ResourceGroup:resourceGroup, Location:location, SizeGB:diskSizeGb, SKU:sku.name}" \
    --output tsv > "$REPORT_FOLDER/Disks_raw.tsv"

echo "Name,ResourceGroup,Location,SizeGB,SKU" > "$REPORT_FOLDER/UnattachedDisks.csv"
cat "$REPORT_FOLDER/Disks_raw.tsv" | tr '\t' ',' >> "$REPORT_FOLDER/UnattachedDisks.csv"
rm "$REPORT_FOLDER/Disks_raw.tsv"

# ----------------------------------------------------------
# 5. SEGURIDAD - Microsoft Entra ID
# ----------------------------------------------------------

echo "Generando reporte de Usuarios (Entra ID)..."

az ad user list \
    --query "[].{DisplayName:displayName, UserPrincipalName:userPrincipalName, AccountEnabled:accountEnabled}" \
    --output tsv > "$REPORT_FOLDER/Users_raw.tsv"

echo "DisplayName,UserPrincipalName,AccountEnabled" > "$REPORT_FOLDER/EntraID_Users.csv"
cat "$REPORT_FOLDER/Users_raw.tsv" | tr '\t' ',' >> "$REPORT_FOLDER/EntraID_Users.csv"
rm "$REPORT_FOLDER/Users_raw.tsv"

echo "Generando reporte de Roles (RBAC)..."

az role assignment list \
    --query "[].{PrincipalName:principalName, Role:roleDefinitionName, Scope:scope}" \
    --output tsv > "$REPORT_FOLDER/Roles_raw.tsv"

echo "PrincipalName,Role,Scope" > "$REPORT_FOLDER/RBAC_Roles.csv"
cat "$REPORT_FOLDER/Roles_raw.tsv" | tr '\t' ',' >> "$REPORT_FOLDER/RBAC_Roles.csv"
rm "$REPORT_FOLDER/Roles_raw.tsv"

# ----------------------------------------------------------
# GENERAR REPORTE HTML CONSOLIDADO
# ----------------------------------------------------------

echo "Generando reporte HTML..."

HTML_FILE="$REPORT_FOLDER/Azure_Full_Report.html"

{
echo "<html><head><title>Azure Critical Report</title></head><body>"
echo "<h1>Azure Critical Services Report</h1>"
echo "<h3>Generated: $(date)</h3>"

for file in Identity.csv VirtualMachines.csv StorageAccounts.csv UnattachedDisks.csv EntraID_Users.csv RBAC_Roles.csv
do
    echo "<h2>$file</h2>"
    echo "<pre>"
    cat "$REPORT_FOLDER/$file"
    echo "</pre>"
done

echo "</body></html>"
} > "$HTML_FILE"

echo "============================================="
echo "Reporte generado en: $REPORT_FOLDER"
echo "============================================="
