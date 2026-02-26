
## Crear una Máquina Virtual (VM) con Linux

```
// Definición de parámetros para mayor flexibilidad
param location string = resourceGroup().location
param vmName string = 'MiVM'
param adminUsername string = 'azureuser'

@secure()
param adminPassword string

// Recurso: Interfaz de Red (necesaria para la VM)
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '/subscriptions/id-sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/default'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Recurso: Máquina Virtual
resource vm 'Microsoft.Compute/virtualMachines@2025-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s' // Tamaño económico
    }
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
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id // Referencia automática a la NIC creada arriba
        }
      ]
    }
  }
}

```

