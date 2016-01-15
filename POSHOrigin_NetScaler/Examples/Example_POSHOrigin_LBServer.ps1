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