# 🚀 Azure Infrastructure Reporter & Automation

Este repositorio contiene un conjunto de utilidades y scripts diseñados para interactuar con **[Azure PowerShell](https://learn.microsoft.com/es-es/powershell/azure/?view=azps-15.3.0)** o **[Azure CLI](https://learn.microsoft.com/es-es/cli/azure/?view=azure-cli-latest)**. El objetivo principal es facilitar la auditoría rápida, el control de costos y la gestión de recursos en entornos de **Microsoft Azure**.

## 📋 Características

El script principal para PowerShell (`azure_report.ps1`) o Bash (`azure_report.sh`) automatiza la recolección de datos críticos:

*   **Identidad:** Verifica la suscripción activa, el ID del Tenant y los detalles del usuario o Service Principal actual.
*   **Virtual Machines (VM):** Tabla resumen con nombres, tamaños de instancia, estados de ejecución y direcciones IP públicas.
*   **Storage Accounts:** Listado de cuentas de almacenamiento con detalles sobre el nivel de acceso y redundancia.
*   **Cost Optimization:** Identificación de **Managed Disks** (discos administrados) en estado `Unattached` que generan cargos innecesarios al no estar asociados a ninguna VM.
*   **Seguridad:** Reporte de usuarios y roles asignados mediante **[Microsoft Entra ID](https://learn.microsoft.com)** (antes Azure AD) para control de acceso.

Por su parte, en (`comandos_basicos_powershell.md`) he recopilado una serie de comandos básicos para usar con PowerShell, y (`comandos_bash_azure.md`) permite realizar acciones sobre los principales servicios con Azure CLI.

## 🛠️ Requisitos Previos para usar un script

*   **Usar Azure Portal o tener Azure PowerShell instalado:** Sigue la [guía oficial de instalación de Microsoft](https://learn.microsoft.com/es-es/powershell/azure/install-azure-powershell?view=azps-15.3.0).
*   **Sesión Iniciada:** El script utiliza tu perfil de autenticación activo. Configúralo con:

```bash
az login
```

*   **Permisos RBAC:** El usuario debe tener al menos permisos de Lector (Reader) a nivel de suscripción para visualizar los recursos.

## ▶️ Uso rápido del script

### En PowerShell ###
*   **Clona este repositorio.**
*   **Habilita la ejecución de scripts (si es necesario): Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process**
*   **Ejecuta el reporte: ./azure_report.ps1.**
  
### En CLI ###
*   **Clona este repositorio.**
*   **Dale permisos de ejecución: chmod +x azure_report.sh.**
*   **Ejecuta el reporte: ./azure_report.sh.**
