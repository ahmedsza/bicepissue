param keyVaultName string
param secretName string

output secretUri string = reference(resourceId('Microsoft.KeyVault/vaults/secrets', split('${keyVaultName}/${secretName}', '/')[0], split('${keyVaultName}/${secretName}', '/')[1]), '2021-06-01-preview').secretUriWithVersion