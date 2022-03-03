@description('The name of the Application Gateawy to be created.')
param appGatewayName string

@description('The FQDN of the Application Gateawy.Must match the TLS Certificate.')
param appGatewayFQDN string = 'api.example.com'

@description('The location of the Application Gateawy to be created')
param location string = resourceGroup().location

@description('The subnet resource id to use for Application Gateway.')
param appGatewaySubnetId string

@description('Set to selfsigned if self signed certificates should be used for the Application Gateway. Set to custom and copy the pfx file to deployment/bicep/gateway/certs/appgw.pfx if custom certificates are to be used')
param appGatewayCertType string

@description('The backend URL of the APIM.')
param primaryBackendEndFQDN string = 'api-internal.example.com'

@description('The Url for the Application Gateway Health Probe.')
param probeUrl string = '/status-0123456789abcdef'
param keyVaultName string
param keyVaultResourceGroupName string

@secure()
param certPassword string

var appGatewayPrimaryPip_var = 'pip-${appGatewayName}'
var appGatewayIdentityId_var = 'identity-${appGatewayName}'

resource appGatewayIdentityId 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: appGatewayIdentityId_var
  location: location
}

resource appGatewayPrimaryPip 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: appGatewayPrimaryPip_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource appGatewayName_resource 'Microsoft.Network/applicationGateways@2019-09-01' = {
  name: appGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentityId.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: appGatewayFQDN
        properties: {
          keyVaultSecretId: reference(extensionResourceId('/subscriptions/${subscription().subscriptionId}/resourceGroups/${keyVaultResourceGroupName}', 'Microsoft.Resources/deployments', 'certificate'), '2020-06-01').outputs.secretUri.value
        }
      }
    ]
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPrimaryPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim'
        properties: {
          backendAddresses: [
            {
              fqdn: primaryBackendEndFQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'default'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
        }
      }
      {
        name: 'https'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: primaryBackendEndFQDN
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: '${appGatewayName_resource.id}/probes/APIM'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: '${appGatewayName_resource.id}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${appGatewayName_resource.id}/frontendPorts/port_80'
          }
          protocol: 'Http'
          hostnames: []
          requireServerNameIndication: false
        }
      }
      {
        name: 'https'
        properties: {
          frontendIPConfiguration: {
            id: '${appGatewayName_resource.id}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${appGatewayName_resource.id}/frontendPorts/port_443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${appGatewayName_resource.id}/sslCertificates/${appGatewayFQDN}'
          }
          hostnames: []
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'apim'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${appGatewayName_resource.id}/httpListeners/https'
          }
          backendAddressPool: {
            id: '${appGatewayName_resource.id}/backendAddressPools/apim'
          }
          backendHttpSettings: {
            id: '${appGatewayName_resource.id}/backendHttpSettingsCollection/https'
          }
        }
      }
    ]
    probes: [
      {
        name: 'APIM'
        properties: {
          protocol: 'Https'
          host: primaryBackendEndFQDN
          path: probeUrl
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
  dependsOn: [
    extensionResourceId('/subscriptions/${subscription().subscriptionId}/resourceGroups/${keyVaultResourceGroupName}', 'Microsoft.Resources/deployments', 'certificate')
  ]
}

module certificate './nested_certificate.bicep' = {
  name: 'certificate'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    managedIdentity: reference(appGatewayIdentityId.id, '2018-11-30', 'full')
    keyVaultName: keyVaultName
    location: location
    appGatewayFQDN: appGatewayFQDN
    appGatewayCertType: appGatewayCertType
    certPassword: certPassword
  }
}