type OS = 'linux' | 'windows'
type AppPlan = {
  name: string
  os: OS
  sku: 'F1' | 'B1' | 'S1'
}
type WebApp = {
  name: string
  hasSlots: bool
  runtime: 'DOTNET|7.0' | 'DOTNET|6.0'
  logContainerName: string
}
type SqlAdministrator = {
  name: string
  principalType: 'Application' | 'Group' | 'User'
  objectId: string
}
type SqlServer = {
  name: string
  administrator: SqlAdministrator
  privateEndpoint: PrivateEndpoint
}
type Db = {
  name: string
  sku: 'Standard' | 'Free' | 'Basic'
}

type SqlConfig = {
  server: SqlServer
  database: Db
}

type RedisSku = {
  name: 'Basic' | 'Standard' | 'Premium'
  capacity: 0 | 1 | 2 | 3 | 4 | 5 | 6
  family: 'C' | 'P'
}
type RedisConfig = {
  name: string
  sku: RedisSku
  privateEndpoint: PrivateEndpoint?
}
type VNet = {
  name: string
  addressSpace: AddressSpace
  subnets: Subnet[]?
}

type AddressSpace = {
  addressPrefixes: string[]
}

type SubnetDelegation = {
  name: string
  properties: {
    serviceName: string
  }
}

type ServiceEndpoint = {
  service: string
}

type Subnet = {
  name: string
  properties: {
    addressPrefix: string
    delegations: SubnetDelegation[]?
    serviceEndpoints: ServiceEndpoint[]?
    privateEndpointNetworkPolicies: 'Enabled' | 'Disabled' | null
  }
}

type PrivateEndpoint = {
  name: string
  dnsGroupName: string
}

param location string

param appPlan AppPlan
param webApp WebApp
param storageAccountName string
param sqlConfig SqlConfig
param redisConfig RedisConfig
param vnet VNet

module vnetDeployment 'modules/network.bicep' = {
  name: 'vnet'
  params: {
    location: location
    vnet: vnet
  }
}

module storageAccountDeployment 'modules/storage-account.bicep' = {
  name: 'storage-account'
  params: {
    blobs: [{ name: webApp.logContainerName, publicAccess: 'None' }]
    location: location
    name: storageAccountName
  }
}

module sqlDeployment 'modules/sql.bicep' = {
  name: 'sql'
  dependsOn: [
    vnetDeployment
  ]
  params: {
    config: sqlConfig
    location: location
    subnetInfo: {
      subnetName: 'sql'
      vNetName: vnet.name
    }
  }
}

module cache 'modules/redis.bicep' = {
  name: 'cache'
  dependsOn: [
    vnetDeployment
  ]
  params: {
    location: location
    name: redisConfig.name
    privateEndpoint: contains(redisConfig, 'privateEndpoint') ? redisConfig.privateEndpoint : null
    sku: redisConfig.sku
    subnet: {
      subnetName: 'cache'
      vNetName: vnet.name
    }
  }
}

module webAppDeployment 'modules/web-app.bicep' = {
  name: 'web-app'
  dependsOn: [
    sqlDeployment
    cache
  ]
  params: {
    appPlan: appPlan
    cacheName: redisConfig.name
    location: location
    sql: {
      databaseName: sqlConfig.database.name
      serverName: sqlConfig.server.name
    }
    storageAccountName: storageAccountName
    subnetInfo: {
      subnetName: 'serverFarms'
      vNetName: vnet.name
    }
    webApp: webApp
  }
}
