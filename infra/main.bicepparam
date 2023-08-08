using './main.bicep'

param location = 'southafricanorth'
param appPlan = {
  name: 'app-wilcob-sbx'
  os: 'windows'
  sku: 'B1'
}
param webApp = {
  name: 'app-wilcob-sbx'
  hasSlots: false
  runtime: 'DOTNET|7.0'
  logContainerName: 'app-wilcob-sbx-logs'
}
param storageAccountName = 'sawilcobsbx'
param sqlConfig = {
  database: {
    name: 'dotnetcoresqldb'
    sku: 'Standard'
  }
  server: {
    name: 'sql-wilcob-sbx'
    administrator: {
      name: 'azure-eqn-za-engteam'
      objectId: '3656eb01-6ede-4c41-8270-359f0239ccb7'
      principalType: 'Group'
    }
    privateEndpoint: {
      name: 'pe-sql-wilcob-sbx'
      dnsGroupName: 'default'
    }
  }
}
param redisConfig = {
  name: 'redis-wilcob-sbx'
  privateEndpoint: {
    name: 'pe-redis-wilcob-sbx'
    dnsGroupName: 'default'
  }
  sku: {
    capacity: 1
    family: 'P'
    name: 'Premium'
  }
}
param vnet = {
  name: 'vnet-wilcob-sbx'
  addressSpace: {
    addressPrefixes: ['10.0.0.0/16']
  }
  subnets: [
    {
      name: 'serverFarms'
      properties: {
        addressPrefix: '10.0.1.0/24'
        delegations: [
          {
            name: 'serverFarms'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
        serviceEndpoints: [
          { service: 'Microsoft.Sql' }
          { service: 'Microsoft.Storage' }
          { service: 'Microsoft.Web' }
        ]
      }
    }
    {
      name: 'cache'
      properties: {
        addressPrefix: '10.0.4.0/24'
        serviceEndpoints: [{ service: 'Microsoft.Web' }]
      }
    }
    {
      name: 'sql'
      properties: {
        addressPrefix: '10.0.7.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }
  ]
}
