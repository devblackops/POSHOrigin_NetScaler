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