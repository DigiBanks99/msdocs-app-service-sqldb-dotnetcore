type Sku = {
  name: 'Basic' | 'Standard' | 'Premium'
  capacity: 0 | 1 | 2 | 3 | 4 | 5 | 6
  family: 'C' | 'P'
}
type SubnetInfo = {
  subnetName: string
  vNetName: string
  resourceGroupName: string?
}
type PrivateEndpoint = {
  name: string
  dnsGroupName: string
}

param name string
param sku Sku
param subnet SubnetInfo
param location string
param privateEndpoint PrivateEndpoint?

resource subnetRef 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' existing = {
  name: '${subnet.vNetName}/${subnet.subnetName}'
  scope: contains(subnet, 'resourceGroupName') && subnet.resourceGroupName != null ? resourceGroup(subnet.resourceGroupName!) : resourceGroup()
}

resource cache 'Microsoft.Cache/redis@2023-05-01-preview' = {
  name: name
  location: location
  properties: {
    sku: sku
    subnetId: subnetRef.id
  }
}

// As of 2023/08/08 Investec will fail this due to a deprecated policy
module privateEndpointDeployment './private-endpoint.bicep' = if (false && privateEndpoint != null) {
  name: 'private-endpoint-cache'
  params: {
    location: location
    privateDnsGroupName: '${privateEndpoint!.name}/${privateEndpoint!.dnsGroupName}'
    privateDnsZoneName: 'privatelink.redis.cache.windows.net'
    privateEndpointName: privateEndpoint!.name
    serviceGroup: 'redisCache'
    serviceId: cache.id
    subnet: {
      subnetName: subnet.subnetName
      vNetName: subnet.vNetName
      resourceGroupName: contains(subnet!, 'resourceGroupName') ? subnet!.resourceGroupName : null
    }
  }
}
