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