param keyVaultName string
param managedIdentity object
param location string
param appGatewayFQDN string

@secure()
param certPassword string
param appGatewayCertType string

var secretName = replace(appGatewayFQDN, '.', '-')
var subjectName = 'CN=${appGatewayFQDN}'
var certData = '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'

resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: managedIdentity.properties.principalId
        tenantId: managedIdentity.properties.tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'import'
            'get'
            'list'
            'update'
            'create'
          ]
        }
      }
    ]
  }
}

resource secretName_certificate 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${secretName}-certificate'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '6.6'
    arguments: ' -vaultName ${keyVaultName} -certificateName ${secretName} -subjectName ${subjectName} -certPwd ${certPassword} -certDataString ${certData} -certType ${appGatewayCertType}'
    scriptContent: '      param(\r\n      [string] [Parameter(Mandatory=$true)] $vaultName,\r\n      [string] [Parameter(Mandatory=$true)] $certificateName,\r\n      [string] [Parameter(Mandatory=$true)] $subjectName,\r\n      [string] [Parameter(Mandatory=$true)] $certPwd,\r\n      [string] [Parameter(Mandatory=$true)] $certDataString,\r\n      [string] [Parameter(Mandatory=$true)] $certType\r\n      )\r\n\r\n      $ErrorActionPreference = \'Stop\'\r\n      $DeploymentScriptOutputs = @{}\r\n      if ($certType -eq \'selfsigned\') {\r\n        $policy = New-AzKeyVaultCertificatePolicy -SubjectName $subjectName -IssuerName Self -ValidityInMonths 12 -Verbose\r\n        \r\n        # private key is added as a secret that can be retrieved in the ARM template\r\n        Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName -CertificatePolicy $policy -Verbose\r\n        \r\n        $newCert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certificateName\r\n\r\n        # it takes a few seconds for KeyVault to finish\r\n        $tries = 0\r\n        do {\r\n          Write-Host \'Waiting for certificate creation completion...\'\r\n          Start-Sleep -Seconds 10\r\n          $operation = Get-AzKeyVaultCertificateOperation -VaultName $vaultName -Name $certificateName\r\n          $tries++\r\n\r\n          if ($operation.Status -eq \'failed\')\r\n          {\r\n          throw \'Creating certificate $certificateName in vault $vaultName failed with error $($operation.ErrorMessage)\'\r\n          }\r\n\r\n          if ($tries -gt 120)\r\n          {\r\n          throw \'Timed out waiting for creation of certificate $certificateName in vault $vaultName\'\r\n          }\r\n        } while ($operation.Status -ne \'completed\')\t\t\r\n      }\r\n      else {\r\n        $ss = Convertto-SecureString -String $certPwd -AsPlainText -Force; \r\n        Import-AzKeyVaultCertificate -Name $certificateName -VaultName $vaultName -CertificateString $certDataString -Password $ss\r\n      }\r\n      '
    retentionInterval: 'P1D'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${managedIdentity.subscriptionId}/resourceGroups/${managedIdentity.resourceGroupName}/providers/${managedIdentity.resourceId}': {}
    }
  }
  dependsOn: [
    resourceId('Microsoft.KeyVault/vaults/accessPolicies', split('${keyVaultName}/add', '/')[0], split('${keyVaultName}/add', '/')[1])
  ]
}

module Microsoft_Resources_deployments_secretName_certificate './nested_Microsoft_Resources_deployments_secretName_certificate.bicep' = {
  name: '${secretName}-certificate'
  params: {
    keyVaultName: keyVaultName
    secretName: secretName
  }
  dependsOn: [
    secretName_certificate
  ]
}

output secretUri string = Microsoft_Resources_deployments_secretName_certificate.properties.outputs.secretUri.value