---
name: intune-device-mgmt
description: Use when managing endpoints with Microsoft Intune. Covers device enrollment, compliance policies, configuration profiles, app deployment, Windows Autopilot, conditional access integration, and remote device actions.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "device management action (e.g., create compliance policy, deploy app)"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$AZURE_CLIENT_ID\" ] && [ -z \"$MS_GRAPH_TOKEN\" ]; then\n  echo '❌ [Hook] Intune credentials not configured. Set AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID.' >&2\n  exit 1\nfi\nif [ -n \"$AZURE_CLIENT_ID\" ] && [ -n \"$AZURE_CLIENT_SECRET\" ] && [ -n \"$AZURE_TENANT_ID\" ]; then\n  export ACCESS_TOKEN=$(node scripts/ms365.mjs token 2>/dev/null)\n  export MS_GRAPH_TOKEN=\"$ACCESS_TOKEN\"\nfi"
---

# Microsoft Intune Device Management

## Overview
Endpoint management using Microsoft Intune via Graph API and PowerShell. Covers device enrollment, compliance policies, configuration profiles, application deployment, and Windows Autopilot.

## Device Enrollment

### Windows Autopilot Profile
```powershell
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

# Create Autopilot deployment profile
$params = @{
    "@odata.type" = "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile"
    DisplayName = "Standard Employee Device"
    Description = "Default Autopilot profile for employee devices"
    Language = "en-US"
    OutOfBoxExperienceSettings = @{
        HidePrivacySettings = $true
        HideEULA = $true
        UserType = "standard"
        DeviceUsageType = "singleUser"
        SkipKeyboardSelectionPage = $true
        HideEscapeLink = $true
    }
    EnrollmentStatusScreenSettings = @{
        AllowDeviceUseBeforeProfileAndAppInstallComplete = $false
        BlockDeviceSetupRetryByUser = $false
        ShowInstallationProgress = $true
        InstallProgressTimeoutInMinutes = 60
    }
}
New-MgDeviceManagementWindowsAutopilotDeploymentProfile @params
```

### Register Autopilot Device
```powershell
# Import hardware hash
$device = @{
    "@odata.type" = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
    SerialNumber = "SERIAL123"
    HardwareIdentifier = [Convert]::ToBase64String([IO.File]::ReadAllBytes("hardware-hash.csv"))
    AssignedUserPrincipalName = "user@contoso.com"
    GroupTag = "Engineering"
}
New-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity @device
```

## Compliance Policies

### Windows Compliance Policy
```bash
curl -X POST https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "@odata.type": "#microsoft.graph.windows10CompliancePolicy",
    "displayName": "Windows 10/11 - Standard Compliance",
    "description": "Baseline compliance for all Windows devices",
    "passwordRequired": true,
    "passwordMinimumLength": 12,
    "passwordRequiredType": "alphanumeric",
    "passwordMinutesOfInactivityBeforeLock": 15,
    "osMinimumVersion": "10.0.19045",
    "bitLockerEnabled": true,
    "secureBootEnabled": true,
    "codeIntegrityEnabled": true,
    "storageRequireEncryption": true,
    "activeFirewallRequired": true,
    "defenderEnabled": true,
    "antivirusRequired": true,
    "antiSpywareRequired": true,
    "realTimeProtectionEnabled": true,
    "scheduledActionsForRule": [{
      "ruleName": "PasswordRequired",
      "scheduledActionConfigurations": [{
        "actionType": "block",
        "gracePeriodHours": 24,
        "notificationTemplateId": ""
      }]
    }]
  }'
```

### macOS Compliance Policy
```powershell
$params = @{
    "@odata.type" = "#microsoft.graph.macOSCompliancePolicy"
    DisplayName = "macOS - Standard Compliance"
    PasswordRequired = $true
    PasswordMinimumLength = 12
    PasswordBlockSimple = $true
    OsMinimumVersion = "14.0"
    SystemIntegrityProtectionEnabled = $true
    StorageRequireEncryption = $true
    FirewallEnabled = $true
    FirewallBlockAllIncoming = $false
    GatekeeperAllowedAppSource = "macAppStoreAndIdentifiedDevelopers"
}
New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $params
```

## Configuration Profiles

### Windows Security Baseline
```bash
curl -X POST https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "@odata.type": "#microsoft.graph.windows10GeneralConfiguration",
    "displayName": "Windows Security Baseline",
    "passwordBlockSimple": true,
    "passwordMinimumLength": 12,
    "passwordMinutesOfInactivityBeforeScreenTimeout": 15,
    "edgeBlockPopups": true,
    "defenderScanType": "full",
    "defenderScheduledScanDay": "everyday",
    "defenderCloudBlockLevel": "high",
    "defenderRequireRealTimeMonitoring": true,
    "defenderRequireNetworkInspectionSystem": true,
    "smartScreenBlockPromptOverride": true,
    "firewallBlockAllIncoming": false,
    "firewallProfileDomain": {
      "firewallEnabled": "allowed",
      "inboundNotificationsBlocked": true
    }
  }'
```

### Wi-Fi Profile
```powershell
$params = @{
    "@odata.type" = "#microsoft.graph.windowsWifiConfiguration"
    DisplayName = "Corporate Wi-Fi"
    WifiSecurityType = "wpaEnterprise"
    Ssid = "CorpWiFi"
    ConnectAutomatically = $true
    ConnectWhenNetworkNameIsHidden = $false
    EapType = "eapTls"
}
New-MgDeviceManagementDeviceConfiguration -BodyParameter $params
```

## Application Deployment

### Deploy Win32 App
```powershell
# Wrap app with IntuneWinAppUtil first:
# IntuneWinAppUtil.exe -c "source_folder" -s "setup.exe" -o "output_folder"

$params = @{
    "@odata.type" = "#microsoft.graph.win32LobApp"
    DisplayName = "7-Zip"
    Description = "7-Zip file archiver"
    Publisher = "Igor Pavlov"
    FileName = "7z2301-x64.exe"
    InstallCommandLine = "7z2301-x64.exe /S"
    UninstallCommandLine = "msiexec /x {23170F69-40C1-2702-2301-000001000000} /qn"
    InstallExperience = @{
        RunAsAccount = "system"
        DeviceRestartBehavior = "suppress"
    }
    DetectionRules = @(@{
        "@odata.type" = "#microsoft.graph.win32LobAppFileSystemDetection"
        Path = "C:\\Program Files\\7-Zip"
        FileOrFolderName = "7z.exe"
        DetectionType = "exists"
    })
    RequirementRules = @(@{
        "@odata.type" = "#microsoft.graph.win32LobAppOperatingSystemRequirement"
        MinimumOperatingSystem = @{ V10_1903 = $true }
        Applicability = "notConfigured"
    })
}
```

### Deploy Microsoft Store App
```bash
curl -X POST https://graph.microsoft.com/beta/deviceAppManagement/mobileApps \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "@odata.type": "#microsoft.graph.winGetApp",
    "displayName": "Visual Studio Code",
    "description": "Code editor",
    "publisher": "Microsoft",
    "packageIdentifier": "Microsoft.VisualStudioCode",
    "installExperience": {
      "runAsAccount": "user"
    }
  }'
```

## Remote Device Actions

### Common Actions
```powershell
# Sync device
Sync-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId

# Remote lock
Lock-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId

# Restart device
Restart-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId

# Retire device (remove company data)
Retire-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId

# Wipe device (factory reset) - USE WITH CAUTION
Wipe-MgDeviceManagementManagedDevice -ManagedDeviceId $deviceId

# Collect diagnostics
$params = @{ CollectDiagnosticsRemoteActionId = (New-Guid).ToString() }
New-MgDeviceManagementManagedDeviceLogCollectionRequest -ManagedDeviceId $deviceId -BodyParameter $params
```

## Reporting

### Device Compliance Summary
```powershell
# Non-compliant devices
Get-MgDeviceManagementManagedDevice -Filter "complianceState eq 'noncompliant'" |
    Select-Object DeviceName, UserDisplayName, ComplianceState,
    OperatingSystem, LastSyncDateTime |
    Format-Table -AutoSize

# Devices not synced in 30 days
$staleDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-ddTHH:mm:ssZ")
Get-MgDeviceManagementManagedDevice -Filter "lastSyncDateTime le $staleDate" |
    Select-Object DeviceName, UserDisplayName, LastSyncDateTime
```

## Best Practices
1. **Start with compliance** — Define compliance policies before deploying configurations
2. **Ring-based deployment** — Pilot group > Early adopters > Broad deployment
3. **Autopilot first** — Use Autopilot for all new Windows devices
4. **Conditional Access** — Link compliance policies to CA for zero-trust access
5. **App protection** — Deploy MAM policies for BYOD before requiring enrollment
6. **Update rings** — Configure Windows Update rings with staged rollouts
7. **Scope tags** — Use scope tags to delegate admin access by region/department
8. **Naming convention** — Prefix: CP=Compliance Policy, CF=Config Profile, AP=App Policy
9. **Test assignments** — Always assign to test group before broad deployment
10. **Monitor regularly** — Review non-compliant devices and stale devices weekly
