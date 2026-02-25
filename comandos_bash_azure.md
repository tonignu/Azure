
# Virtual Machines (VMs)

**Detener todas las VMs activas**
```
az vm list -d --query "[?powerState=='VM running'].id" -o tsv | xargs -I {} az vm stop --ids {}
```

**Obtener IPs públicas de todas las VMs**
```
az vm list-ip-addresses --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" -o tsv
```

**Listar todas las VMs con el tag "Proyecto"**
```
az vm list --tag Proyecto=MyProjectName --query "[].id" -o tsv
```

**Verificar el estado de salud de todas las VMs**
```
az vm list -d --query "[].[name, powerState, provisioningState]" -o table
```


# Storage Account + Blob Storage

**Calcular tamaño total de un container**
```
az storage blob list \
  --account-name <storage-account> \
  --container-name <container> \
  --query "[].properties.contentLength" \
  -o tsv | awk '{sum+=$1} END {print sum}'
```

**Sincronizar carpeta local con Blob Storage**
```
azcopy sync "./carpeta-local" "https://<account>.blob.core.windows.net/<container>"
```


# Microsoft Entra ID + RBAC

**Listar usuarios y último login**
```
az ad user list --query "[].[userPrincipalName, signInActivity.lastSignInDateTime]" -o table
```

**Ver qué identidad estoy usando actualmente**
```
az account show
```

**Ver el objeto del usuario/servicio**
```
az ad signed-in-user show
```

# Azure Functions (Serverless)

**Listar todas las Functions y su memoria**
```
az functionapp list --query "[].[name, resourceGroup, kind]" -o table
```


# Limpieza

**Encontrar discos que no están en uso**
```
az disk list --query "[?managedBy==null].id" -o tsv
```

**Listar snapshots antiguos**
```
az snapshot list --query "[?timeCreated<'2023-01-01'].id" -o tsv
```
