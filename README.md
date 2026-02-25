# 🚀 Azure Infrastructure Reporter & Automation

Este repositorio contiene un conjunto de utilidades y scripts en Bash diseñados para interactuar con la **[Azure CLI](https://learn.microsoft.com)**. El objetivo principal es facilitar la auditoría rápida, el control de costos y la gestión de recursos en entornos de **Microsoft Azure**.

## 📋 Características

El script principal (`azure_report.sh`) automatiza la recolección de datos críticos:

*   **Identidad:** Verifica la suscripción activa, el ID del Tenant y los detalles del usuario o Service Principal actual.
*   **Virtual Machines (VM):** Tabla resumen con nombres, tamaños de instancia, estados de ejecución y direcciones IP públicas.
*   **Storage Accounts:** Listado de cuentas de almacenamiento con detalles sobre el nivel de acceso y redundancia.
*   **Cost Optimization:** Identificación de **Managed Disks** (discos administrados) en estado `Unattached` que generan cargos innecesarios al no estar asociados a ninguna VM.
*   **Seguridad:** Reporte de usuarios y roles asignados mediante **[Microsoft Entra ID](https://learn.microsoft.com)** (antes Azure AD) para control de acceso.

El script de comandos (`script_comandos.md`) es una guia básica de los principales comandos de Azure en PowerShell

## 🛠️ Requisitos Previos

*   **Azure CLI Instalado:** Sigue la [guía oficial de instalación de Microsoft](https://learn.microsoft.com).
*   **Sesión Iniciada:** El script utiliza tu perfil de autenticación activo. Configúralo con:

```bash
az login
```

*   **Permisos RBAC:** El usuario debe tener al menos permisos de Lector (Reader) a nivel de suscripción para visualizar los recursos.

## 🚀 Uso rápido del script principal

*   **Clona este repositorio.**
*   **Dale permisos de ejecución: chmod +x azure_report.sh.**
*   **Ejecuta el reporte: ./azure_report.sh.**
