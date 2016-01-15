#Requires -Version 5.0
#Requires -Module NetScaler

enum Ensure {
    Absent
    Present
}

[DscResource()]
class LBVirtualServer {
    [DscProperty(key)]
    [string]$Name

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [DscProperty(Mandatory)]
    [string]$NetScalerFQDN

    [DscProperty(Mandatory)]
    [pscredential]$Credential

    [DscProperty(Mandatory)]
    [string]$IPAddress

    [DscProperty(Mandatory)]
    [ValidateRange(1, 65534)]
    [int]$Port

    [DscProperty()]
    [ValidateSet('DHCPRA','DIAMTER', 'DNS', 'DNS_TCP', 'DLTS', 'FTP', 'HTTP', 'MSSQL', 
        'MYSQL', 'NNTP', 'PUSH','RADIUS', 'RDP', 'RTSP', 'SIP_UDP', 'SSL', 'SSL_BRIDGE', 
        'SSL_DIAMETER', 'SSL_PUSH', 'SSL_TCP', 'TCP', 'TFTP', 'UDP')]
    [string]$ServiceType = 'HTTP'

    [DscProperty()]
    [ValidateSet('ROUNDROBIN', 'LEASTCONNECTION', 'LEASTRESPONSETIME', 'LEASTBANDWIDTH', 
        'LEASTPACKETS', 'CUSTOMLOAD', 'LRTM', 'URLHASH', 'DOMAINHASH', 'DESTINATIONIPHASH', 
        'SOURCEIPHASH', 'TOKEN', 'SRCIPDESTIPHASH', 'SRCIPSRCPORTHASH', 'CALLIDHASH')]
    [string]$LBMethod = 'ROUNDROBIN'

    [DscProperty()]
    [ValidateLength(0, 256)]
    [string]$Comments = [string]::Empty

    [DscProperty()]
    #[ValidateSet('ENABLED', 'DISABLED', '')]
    [string]$State = 'ENABLED'

    [DscProperty()]
    [bool]$ParameterExport = $false

    [void]Set() {
        try {
            Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
            # Try to get the VIP
            $vip = Get-NSLBVirtualServer -Name $this.Name
            if ($null -ne $vip) {
                # Run tests and set any needed attributes to match desired configuration
                if ($vip.ipv46 -ne $this.IPAddress) {
                    Set-NSLBVirtualServer -Name $this.Name -IPAddress $this.IPAddress -Confirm:$false
                    Write-Verbose -Message "Setting virtual server IP [$($this.IPAddress)]"
                }
                if ($vip.port -ne $this.Port) {
                    Write-Warning -Message 'NetScaler does not support changing virtual server port on an existing virtual server. Virtual server must be deleted and recreated.'
                }
                if ($vip.servicetype -ne $this.ServiceType) {
                    Write-Warning -Message 'NetScaler does not support changing virtual server service type on an existing virtual server. Virtual server must be deleted and recreated.'
                }
                if ($vip.lbmethod -ne $this.LBMethod) { 
                    Set-NSLBVirtualServer -Name $this.Name -LBMethod $this.LBMethod
                    Write-Verbose -Message "Setting virtual server load balance method [$($this.LBMethod)]"
                }
                if ($vip.comment -ne $this.Comments) {
                    Write-Verbose -Message "Setting virtual server comments [$($this.Comments)]"
                    Set-NSLBVirtualServer -Name $this.Name -Comment $this.Comments -Force
                }
                if ($vip.state -ne $this.State) { 
                    Write-Verbose -Message "Setting virtual server state [$($this.State)]"
                    if ($this.State -eq 'ENABLED') {
                        Enable-NSLBVirtualServer -Name $this.Name -Force
                    } else {
                        Disable-NSLBVirtualServer -Name $this.Name -Force
                    }
                }
            } else {
                Write-Verbose -Message "Creating virtual server [$($this.Name)]"
                $params = @{
                    Name = $this.Name
                    IPAddress = $this.IPAddress
                    ServiceType = $this.ServiceType
                    Port = $this.Port
                    LBMethod = $this.LBMethod
                    Comment = $this.Comments
                    Confirm = $false
                }
                $newVIP = New-NSLBVirtualServer @params
            }
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        } catch {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
            Write-Error 'There was a problem setting the resource'
            Write-Error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-Error $_
        }
    }

    [bool]Test() {

        $pass = $true

        try {
            Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
            # Try to get the VIP
            $vip = Get-NSLBVirtualServer -Name $this.Name

            if ($this.Ensure = [Ensure]::Present) {
                if ($null -ne $vip) {
                    Write-Verbose -Message "VIP [$($this.Name)] exists"
                    # Run tests against VIP
                    if ($vip.ipv46 -ne $this.IPAddress) {
                        Write-Verbose -Message "Virtual server IP address does not match [$($vip.IPAddress) <> $($this.IPAddress)"
                        #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                        $pass = $false
                    }
                    if ($vip.port -ne $this.Port) {
                        Write-Verbose -Message "Virtual server port does not match [$($vip.port) <> $($this.Port)"
                        #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                        $pass = $false
                    }
                    if ($vip.servicetype -ne $this.ServiceType) {
                        Write-Verbose -Message "Virtual server service type does not match [$($vip.servicetype) <> $($this.ServiceType)"
                        #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                        $pass = $false
                    }
                    if ($vip.lbmethod -ne $this.LBMethod) { 
                        Write-Verbose -Message "Virtual server load balance method does not match [$($vip.lbmethod) <> $($this.LBMethod)"
                        #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                        $pass = $false
                    }
                    if ($vip.comment -ne $this.Comments) {
                        Write-Verbose -Message "Virtual server comments do not match [$($vip.comment) <> $($this.Comments)]"
                        #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                        $pass = $false
                    }
                    if ($vip.curstate -ne 'DOWN') {
                        if ($this.State -eq 'DISABLED') { $this.State = 'OUT OF SERVICE'}
                        if ($vip.curstate -ne $this.State) { 
                            Write-Verbose -Message "Virtual server state does not match [$($vip.curstate) <> $($this.State)]"
                            #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                            $pass = $false
                        }
                    }

                    #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                    #return $true
                } else {
                    Write-Verbose -Message "VIP [$($this.Name)] not found"
                    $pass = $false
                }
            } else {
                if ($null -ne $vip) {
                    $pass = $false
                    #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                    #return $false # VIP should not exist but does
                } else {
                    #Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
                    #return $true # VIP should not exist and doesn't. All good
                }
            }
        }
        catch {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
            Write-Error 'There was a problem setting the resource'
            Write-Error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-Error $_
            #return $true
        }

        # Export the resource parameters if told to.
        # These values can be used by other DSC resources down the chain
        if ($this.ParameterExport) {
            $fileName = "LBVirtualServer_$($this.Name).json"
            $json = $this.Get() | ConvertTo-Json
            $folder = Join-Path -Path $env:USERPROFILE -ChildPath '.poshorigin'
            if (-Not (Test-Path -Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force
            }
            $fullPath = Join-Path -Path $folder -ChildPath $fileName
            Write-Verbose -Message "Exporting parameters to [$fullPath]"
            $json | Out-File -FilePath $fullPath -Force
        }

        try {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        } catch {
            # Do nothing
        }
        return $pass
    }

    [LBVirtualServer]Get() {
        Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false

        $vip = Get-NSLBVirtualServer -Name $this.Name -ErrorAction SilentlyContinue
        
        $obj = [LBVirtualServer]::new()
        $obj.Name = $this.Name
        $obj.IPAddress = $this.IPAddress
        $obj.NetScalerFQDN = $this.NetScalerFQDN
        $obj.Credential = $this.Credential
        $obj.ParameterExport = $this.ParameterExport
        if ($vip) {
            $obj.Ensure = [ensure]::Present
            $obj.Port = $vip.port
            $obj.ServiceType = $vip.servicetype
            $obj.LBMethod = $vip.lbmethod
            $obj.State = $vip.curstate
        } else {
            $obj.Ensure = [ensure]::Absent
        }
        Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        return $obj
    }
}

[DscResource()]
class LBServer {
    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    [DscProperty(Mandatory)]
    [string]$NetScalerFQDN

    [DscProperty(Mandatory)]
    [pscredential]$Credential

    [DscProperty(Mandatory)]
    [string]$IPAddress

    [DscProperty()]
    [ValidateLength(0, 256)]
    [string]$Comments = ''

    [DscProperty()]
    [ValidateRange(0, 4094)]
    [int]$TrafficDomainId

    [DscProperty()]
    [ValidateSet('ENABLED', 'DISABLED')]
    [string]$State = 'ENABLED'

    [DscProperty()]
    [bool]$ParameterExport = $false

    [void]Set() {
        try {
            Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
            # Try to get the server
            $server = Get-NSLBServer -Name $this.Name -ErrorAction SilentlyContinue
            if ($null -ne $server) {
                # Run tests and set any needed attributes to match desired configuration
                if ($server.ipaddress -ne $this.IPAddress) {
                    Write-Verbose -Message "Setting server IP [$($this.IPAddress)]"
                    Set-NSLBServer -Name $this.Name -IPAddress $this.IPAddress -Force
                }
                if ($server.comment -ne $this.Comments) {
                    Write-Verbose -Message "Setting server comments [$($this.Comments)]"
                    Set-NSLBServer -Name $this.Name -Comment $this.Comments -Force
                }
                if ($server.state -ne $this.State) { 
                    Write-Verbose -Message "Setting server state [$($this.State)]"
                    if ($this.State -eq 'ENABLED') {
                        Enable-NSLBServer -Name $this.Name -Force
                    } else {
                        Disable-NSLBServer -Name $this.Name -Force
                    }
                }
            } else {
                Write-Verbose -Message "Creating server [$($this.Name)]"
                $params = @{
                    Name = $this.Name
                    IPAddress = $this.IPAddress
                    Comment = $this.Comments
                    Confirm = $false
                }
                if ($null -ne $this.TrafficDomainId) {
                    $params.TrafficDomainId = $this.TrafficDomainId
                }
                $newVIP = New-NSLBServer @params
            }
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        } catch {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
            Write-Error 'There was a problem setting the resource'
            Write-Error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-Error $_
        }
    }

    [bool]Test() {

        $pass = $true

        Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        # Try to get the server
        $server = Get-NSLBServer -Name $this.Name -ErrorAction SilentlyContinue

        if ($this.Ensure = [Ensure]::Present) {
            if ($server) {
                Write-Verbose -Message "Server [$($this.Name)] exists"
                # Run tests against server
                if ($server.ipaddress -ne $this.IPAddress) {
                    Write-Verbose -Message "Server IP address does not match [$($server.ipaddress) <> $($this.IPAddress)]"
                    $pass = $false
                }
                if ($server.comment -ne $this.Comments) {
                    Write-Verbose -Message "Server comments do not match [$($server.comment) <> $($this.Comments)]"
                    $pass = $false
                }
                if ($server.td -ne $this.TrafficDomainid) {
                    Write-Verbose -Message "Server traffic domain ID does not match [$($server.td) <> $($this.TrafficDomainId)]"
                    $pass = $false
                }
                if ($server.state -ne $this.State) { 
                    Write-Verbose -Message "Server state does not match [$($server.state) <> $($this.State)]"
                    $pass = $false
                }
            } else {
                Write-Verbose -Message "Server [$($this.Name)] not found"
                $pass = $false
            }
        } else {
            if ($server) {
                $pass = $false
            }
        }

        # Export the resource parameters if told to.
        # These values can be used by other DSC resources down the chain
        if ($this.ParameterExport) {
            $fileName = "LBServer_$($this.Name).json"
            $json = $this.Get() | ConvertTo-Json
            $folder = Join-Path -Path $env:USERPROFILE -ChildPath '.poshorigin'
            if (-Not (Test-Path -Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force
            }
            $fullPath = Join-Path -Path $folder -ChildPath $fileName
            Write-Verbose -Message "Exporting parameters to [$fullPath]"
            $json | Out-File -FilePath $fullPath -Force
        }

        try {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        } catch {
            # Do nothing
        }

        return $pass
    }

    [LBServer]Get() {
        Connect-NetScaler -NSIP $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false

        $s = Get-NSLBServer -Name $this.Name -ErrorAction SilentlyContinue
        
        $obj = [LBServer]::new()
        $obj.ParameterExport = $this.ParameterExport
        if ($s) {
            $obj.Name = $s.Name
            $obj.IPAddress = $s.ipv46
            $obj.comments = $s.comment
            $obj.TrafficDomainId = $s.td
            $obj.State = $s.state
        } else {
            $obj.Ensure = [ensure]::Absent
        }
        Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        return $obj
    }
}