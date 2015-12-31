[![Stories in Ready](https://badge.waffle.io/devblackops/POSHOrigin_NetScaler.png?label=ready&title=Ready)](https://waffle.io/devblackops/POSHOrigin_NetScaler)
[![Build status](https://ci.appveyor.com/api/projects/status/5l0movhn89rexh0g?svg=true)](https://ci.appveyor.com/project/devblackops/poshorigin-netscaler)

# POSHOrigin_NetScaler
POSHOrigin_NetScaler is a set of PowerShell 5 based DSC resources for managing Citrix NetScaler load balancer objects via DSC.

## Resources

* **LBServer** Manages a load balancer server instance
* **LBVirtualServer** Manages a load balancer virtual server instance

### LBServer

Created, modifies, or deletes a load balancer server instance

Parameters
----------

| Name            | Type         | Required | Description
| :---------------|:-------------|:---------|:-----------|
| Name            | string       | True     | The name of the instance
| Ensure          | string       | False    | Denotes if resource should exist or not exist
| NetScalerFQDN   | string       | True     | The FQDN of the NetScaler appliance to connect to
| Credential      | pscredential | True     | Credential with rights on NetScaler to manager load balancer server instances
| IPAddress       | string       | True     | The IP address of the server instance
| Comments        | string       | False    | Comments associated with the server instance
| TrafficDomainId | int          | False    | Identifies the traffic domain in which you want to configure the server instance
| State           | string       | False    | State of the server instance. Valid values are 'ENABLED', 'DISABLED'



### LBVirtualServer

Created, modifies, or deletes a load balancer server instance

Parameters
----------

| Name            | Type         | Required | Description
| :---------------|:-------------|:---------|:-----------|
| Name            | string       | True     | The name of the instance
| Ensure          | string       | False    | Denotes if resource should exist or not exist
| NetScalerFQDN   | string       | True     | The FQDN of the NetScaler appliance to connect to
| Credential      | pscredential | True     | Credential with rights on NetScaler to manager load balancer server instances
| IPAddress       | string       | True     | The IP address of the server instance
| Port            | int          | False    | Port number for the virtual server
| ServiceType     | string       | False    | Protocol used by the virtual server
| LBMethod        | string       | False    | Load balancing method used by the virtual server
| Comments        | string       | False    | Comments associated with the server instance
| State           | string       | False    | State of the virtual server instance. Valid values are 'ENABLED', 'DISABLED'

## Versions

### 1.1.0

* Initial release

## Examples

### LBServer

This example shows how to use the **LBServer** resource within the context of a [POSHOrigin](https://github.com/devblackops/POSHOrigin) configuration file.

```PowerShell
resource 'POSHOrigin_NetScaler:LBServer' 'serverxyz' @{
    Ensure = 'Present'
    NetScalerFQDN = 'mynetscaler.mydomain.com'
    IPAddress = '192.168.100.100'
    Comments = 'This is a comment'
    TrafficDomainId = 1
    State = 'ENABLED'
    Credential = Get-POSHOriginSecret 'pscredential' @{
        username = 'administrator'
        password = 'K33p1t53cr3tK33p1t5@f3'
    }
}
```

This example show how to use the **LBServer** resource within a traditional DSC configuration file.

```PowerShell
Configuration Example_LBServer {
    param(
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$IPAddress,

        [Parameter(Mandatory)]
        [string]$NetScalerFQDN,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [string]$Comments,

        [int]$TrafficDomainId,

        [string]$State
    )

    Import-DscResource -Name LBServer -ModuleName POSHOrigin_NetScaler

    Node $NodeName {
        LBServer "Create$Name" {
            Ensure = 'Present'
            Name = $Name
            IPAddress = $IPAddress
            NetScalerFQDN = $NetScalerFQDN
            Credential = $Credential
            Comments = $Comments
            TrafficDomainId = $TrafficDomainId
            State = $State
        }
    }
}
```

### LBVirtualServer

This example shows how to use the **LBVirtualServer** resource within the context of a [POSHOrigin](https://github.com/devblackops/POSHOrigin) configuration file.

```PowerShell
resource 'POSHOrigin_NetScaler:LBServer' 'lbserverxyz' @{
    Ensure = 'Present'
    NetScalerFQDN = 'mynetscaler.mydomain.com'
    Comments = 'This is a comment'
    IPAddress = '192.168.100.101'
    Port = 80
    ServiceType = 'HTTP'
    LBMethod = 'ROUNDROBIN'    
    State = 'ENABLED'
    Credential = Get-POSHOriginSecret 'pscredential' @{
        username = 'administrator'
        password = 'K33p1t53cr3tK33p1t5@f3'
    }
}
```

This example show how to use the **LBVirtualServer** resource within a traditional DSC configuration file.

```PowerShell
Configuration Example_LBVirtualServer {
    param(
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$IPAddress,

        [Parameter(Mandatory)]
        [string]$NetScalerFQDN,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [int]$Port,

        [string]$ServiceType,

        [string]$LBMethod,

        [string]$Comments,

        [string]$State
    )

    Import-DscResource -Name LBVirtualServer -ModuleName POSHOrigin_NetScaler

    Node $NodeName {
        LBVirtualServer "Create$Name" {
            Ensure = 'Present'
            Name = $Name
            IPAddress = $IPAddress
            NetScalerFQDN = $NetScalerFQDN
            Credential = $Credential
            Port = $Port
            ServiceType = $ServiceType
            LBMethod = $LBMethod
            Comments = $Comments
            State = $State
        }
    }
}
```
