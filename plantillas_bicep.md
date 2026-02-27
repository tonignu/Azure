## Plantillas Bicep (copiar cada código y guardar con extensión .bicep)

### Crear Red Principal y Subred (red.bicep)
```
param location string = resourceGroup().location
param vnetName string = 'VNet-Principal'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      {
        name: 'default'
        properties: { addressPrefix: '10.0.1.0/24' }
      }
    ]
  }
}

// EXPORTAMOS el ID de la subred para que la VM sepa dónde conectarse
output subnetId string = vnet.properties.subnets[0].id

```

### Crear una Máquina Virtual (vm.bicep) con: 1 vCPU y 1GB de RAM (Standard_B1s), SO Linux (Ubuntu 22.04) e IP Pública

```
@description('Subred')
param subnetId string // Recibido desde el módulo de red

@description('Nombre de la máquina virtual')
param vmName string  // Sin hardcorear para que Azure lo pida

@description('Usuario administrador')
param adminUsername string = 'azureuser'

@description('Contraseña del administrador')
@secure()
param adminPassword string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

// 1. IP Pública (para poder entrar por SSH)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${vmName}-pip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// 2. Interfaz de Red
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIP.id }
          subnet: { id: subnetId } // Usamos el ID que nos pasa el módulo de Red
        }
      }
    ]
  }
}

// 3. La Máquina Virtual (Ubuntu 22.04)
resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B1s' }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
      }
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id }]
    }
  }
}

```


### Crear una BBDD MySQL (bbdd.bicep) sobre: 1 vCPU, 2GB RAM (Standard_B1ms) y disco de 20GB
```
param location string = resourceGroup().location
param serverName string = 'mysql-server-${uniqueString(resourceGroup().id)}'
param dbName string = 'mibasedatos'
param adminUsername string = 'mysqladmin'

@secure()
param adminPassword string

// 1. Servidor Flexible de MySQL
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_B1ms' // Clase económica
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    storage: {
      storageSizeGB: 20
      iops: 360
    }
    version: '8.0.21'
  }
}

// 2. La Base de Datos dentro del servidor
resource mysqlDB 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = {
  parent: mysqlServer
  name: dbName
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

// 3. Regla de Firewall (Permite el acceso desde servicios de Azure)
resource firewallAzure 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-12-30' = {
  parent: mysqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

```

### Módulo principal que lo orquesta todo (main.bicep)
```
param location string = resourceGroup().location
param projectName string = 'proyecto-final'

@secure()
param vmPassword string
@secure()
param dbPassword string

// Módulo 1: RED
module red './red.bicep' = {
  name: 'deploy-red'
  params: { 
    location: location
    vnetName: '${projectName}-vnet'
  }
}

// Módulo 2: VM
module vm './vm.bicep' = {
  name: 'deploy-vm'
  params: {
    location: location
    vmName: '${projectName}-vm'
    adminUsername: 'azureuser'
    adminPassword: vmPassword
    subnetId: red.outputs.subnetId // Dependencia de Red
  }
}

// Módulo 3: DATOS (MySQL)
module datos './bbdd.bicep' = {
  name: 'deploy-bbdd'
  params: {
    location: location
    serverName: '${projectName}-sql-${uniqueString(resourceGroup().id)}'
    dbName: 'appdb'
    adminUsername: 'dbadmin'
    adminPassword: dbPassword
  }
}


```


Ejecutar en PowerShell:
```
New-AzResourceGroupDeployment `
  -ResourceGroupName "MiGrupoDeRecursos" `
  -TemplateFile ".\main.bicep"
```

O en Azure CLI:
```
az deployment group create \
  --resource-group MiGrupoDeRecursos \
  --template-file main.bicep
```
