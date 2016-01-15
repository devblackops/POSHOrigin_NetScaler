$DscConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
        @{
            NodeName = 'localhost'
        }
    )
}

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