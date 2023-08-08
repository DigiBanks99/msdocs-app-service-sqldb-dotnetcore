type BlobContainer  = {
  name: string
  publicAccess: 'Blob' | 'Container' | 'None'
}
param name string
param location string
param blobs BlobContainer[]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    containerDeleteRetentionPolicy: {
      days: 10
      enabled: true
    }
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for blob in blobs: {
  parent: blobServices
  name: blob.name
  properties: {
    publicAccess: blob.publicAccess
  }
}]
