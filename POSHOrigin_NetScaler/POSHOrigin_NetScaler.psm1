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
    [string]$Service

    [DscProperty()]
    [string]$ServiceGroup

    [DscProperty()]
    [ValidateLength(0, 256)]
    [string]$Comments = [string]::Empty

    [DscProperty()]
    #[ValidateSet('ENABLED', 'DISABLED', '')]
    [string]$State = 'ENABLED'

    [DscProperty()]
    [bool]$ParameterExport = $false

    [LBVirtualServer]Get() {
        [ref]$t = $null
        if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
            Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        } else {
            Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        }

        $vip = Get-NSLBVirtualServer -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue
        
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

    [void]Set() {
        try {
            $vip = $this.Get()

            switch ($this.Ensure) {
                'Present' {
                    [ref]$t = $null
                    if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
                        Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
                    } else {
                        Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
                    }

                    # Does the record already exist?
                    if ($vip.Ensure -ne [ensure]::Present) {
                        # Create VIP
                        Write-Verbose -Message "Creating virtual server [$($this.Name)]"
                        $params = @{
                            Name = $this.Name
                            IPAddress = $this.IPAddress
                            ServiceType = $this.ServiceType
                            Port = $this.Port
                            LBMethod = $this.LBMethod
                            Comment = $this.Comments
                            Verbose = $false
                            Confirm = $false
                        }
                        New-NSLBVirtualServer @params
                        $vip = $this.Get()
                        [ref]$t = $null
                        if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
                            Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
                        } else {
                            Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
                        }
                    }

                    # Run tests and set any needed attributes to match desired configuration

                    # IP check
                    if ($vip.IPAddress -ne $this.IPAddress) {
                        Set-NSLBVirtualServer -Name $this.Name -IPAddress $this.IPAddress -Verbose:$false -Confirm:$false
                        Write-Verbose -Message "Setting virtual server IP [$($this.IPAddress)]"
                    }

                    # Port check
                    if ($vip.Port -ne $this.Port) {
                        Write-Warning -Message 'NetScaler does not support changing virtual server port on an existing virtual server. Virtual server must be deleted and recreated.'
                    }

                    # Service type check
                    if ($vip.ServiceType -ne $this.ServiceType) {
                        Write-Warning -Message 'NetScaler does not support changing virtual server service type on an existing virtual server. Virtual server must be deleted and recreated.'
                    }

                    # LB method check
                    if ($vip.LBMethod -ne $this.LBMethod) { 
                        Set-NSLBVirtualServer -Name $this.Name -LBMethod $this.LBMethod -Verbose:$false -Force
                        Write-Verbose -Message "Setting virtual server load balance method [$($this.LBMethod)]"
                    }

                    # Comments check
                    if ($vip.Comments -ne $this.Comments) {
                        Write-Verbose -Message "Setting virtual server comments [$($this.Comments)]"
                        Set-NSLBVirtualServer -Name $this.Name -Comment $this.Comments -Verbose:$false -Force
                    }

                    # Service group binding check
                    $bindings = Get-NSLBVirtualServerBinding -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue
                    $sgBinding = $bindings | where servicegroupname -eq $this.ServiceGroup
                    if ($this.ServiceGroup) {
                        if (-Not $sgBinding) {
                            Write-Verbose -Message "Adding virtual server service group binding [$($this.ServiceGroup)]"
                            Add-NSLBVirtualServerBinding -VirtualServerName $this.Name -ServiceGroupName $this.ServiceGroup -Verbose:$false -Force
                        }
                    }

                    # Service binding check
                    $bindings = Get-NSLBVirtualServerBinding -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue
                    $serviceBinding = $bindings | where servicename -eq $this.Service
                    if ($this.Service) {
                        if (-Not $serviceBinding) {
                            Write-Verbose -Message "Adding virtual server service binding [$($this.Service)]"
                            Add-NSLBVirtualServerBinding -VirtualServerName $this.Name -ServiceName $this.Service -Verbose:$false -Force
                        }
                    }

                    # State check
                    if ($vip.State -ne 'DOWN') {
                        if ($vip.State -ne $this.State) { 
                            Write-Verbose -Message "Setting virtual server state [$($this.State)]"
                            if ($this.State -eq 'ENABLED') {
                                Enable-NSLBVirtualServer -Name $this.Name -Verbose:$false -Force
                                # Check that the enable worked
                                $vip2 = Get-NSLBVirtualServer -Name $this.Name -Verbose:$false
                                if (-Not $vip2.State -eq 'ENABLED') {
                                    Write-Error -Message "Enabling the virtual server was unsuccessful. The current state is $($vip.curstate)"
                                }
                            } else {
                                Disable-NSLBVirtualServer -Name $this.Name -Verbose:$false -Force
                            }
                        }
                    }
                }
                'Absent' {
                    if ($vip.Ensure -eq [ensure]::Present) {
                        # Remove VIP
                        Write-Verbose -Message "Removing virtual server: $($this.Name)"
                        Remove-NSLBVirtualServer -Name $this.Name -Verbose:$false -Force
                    } else {
                        # Do nothing
                    }
                }
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

        $vip = $this.Get()
        $pass = $true
        try {
            Write-Verbose -Message "Validating that virtual server $($this.Name) is $($this.Ensure.ToString().ToLower())"
            if ($this.Ensure -ne $vip.Ensure) { return $false }

            if ($this.Ensure -eq [Ensure]::Present) {
                if ($null -ne $vip) {
                    Write-Verbose -Message "VIP [$($this.Name)] exists"
                    $bindings = Get-NSLBVirtualServerBinding -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue

                    # IP check
                    if ($vip.IPAddress -ne $this.IPAddress) {
                        Write-Verbose -Message "Virtual server IP address does not match [$($vip.IPAddress) <> $($this.IPAddress)"
                        $pass = $false
                    }

                    # Port check
                    if ($vip.Port -ne $this.Port) {
                        Write-Verbose -Message "Virtual server port does not match [$($vip.port) <> $($this.Port)"
                        $pass = $false
                    }

                    # Service type check
                    if ($vip.ServiceType -ne $this.ServiceType) {
                        Write-Verbose -Message "Virtual server service type does not match [$($vip.servicetype) <> $($this.ServiceType)"
                        $pass = $false
                    }

                    # LB method check
                    if ($vip.LBMethod -ne $this.LBMethod) { 
                        Write-Verbose -Message "Virtual server load balance method does not match [$($vip.lbmethod) <> $($this.LBMethod)"
                        $pass = $false
                    }

                    # Comment check
                    if ($vip.comment -ne $this.Comments) {
                        Write-Verbose -Message "Virtual server comments do not match [$($vip.comment) <> $($this.Comments)]"
                        $pass = $false
                    }

                    # Service group binding check
                    if ($this.ServiceGroup) {
                        $sgBinding = $bindings | where servicegroupname -eq $this.ServiceGroup
                        if (-Not $sgBinding) { 
                            Write-Verbose -Message 'Virtual server has no service group binding'
                            $pass = $false
                        } else {
                            if ($sgBinding.servicegroupname -ne $this.ServiceGroup) {
                                Write-Verbose -Message "Virtual server binding service group does not match [$($sgBinding.servicegroupname) <> $($this.ServiceGroup)]"
                                $pass = $false
                            }
                        }
                    } else {
                        if ($this.Service) {
                            $unknownBindings = $bindings | where servicename -ne $this.Service
                            if ($unknownBindings) {
                                $pass = $false
                                foreach ($unknownBinding in $unknownBindings) {
                                    Write-Verbose -Message "Virtual server service group binding exists [$($unknownBinding.servicegroupname)] and should not"
                                }
                            }
                        }
                    }

                    # Service binding check
                    $serviceBinding = $bindings | where servicename -eq $this.Service
                    if ($this.Service) {
                        if (-Not $serviceBinding) { 
                            Write-Verbose -Message 'Virtual server has no service binding'
                            $pass = $false
                        } else {
                            if ($serviceBinding.servicename -ne $this.Service) {
                                Write-Verbose -Message "Virtual server binding service does not match [$($serviceBinding.servicename) <> $($this.Service)]"
                                $pass = $false
                            }
                        }
                    } else {
                        if ($this.Service) {
                            $unknownBindings = $bindings | where servicegroupname -ne $this.ServiceGroup
                            if ($unknownBindings) {
                                $pass = $false
                                foreach ($unknownBinding in $unknownBindings) {
                                    Write-Verbose -Message "Virtual server service group binding exists [$($unknownBinding.servicegroupname)] and should not"
                                }
                            }
                        }
                    }

                    # State check
                    if ($vip.curstate -ne 'DOWN') {
                        if ($this.State -eq 'DISABLED') { $this.State = 'OUT OF SERVICE'}
                        if ($vip.curstate -ne $this.State) { 
                            Write-Verbose -Message "Virtual server state does not match [$($vip.curstate) <> $($this.State)]"
                            $pass = $false
                        }
                    }
                } else {
                    Write-Verbose -Message "VIP [$($this.Name)] not found"
                    $pass = $false
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
            [ref]$t = $null
            if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
                Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
            } else {
                Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
            }
            # Try to get the server
            $server = Get-NSLBServer -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue

            if ($null -ne $server) {
                # Run tests and set any needed attributes to match desired configuration
                if ($server.ipaddress -ne $this.IPAddress) {
                    Write-Verbose -Message "Setting server IP [$($this.IPAddress)]"
                    Set-NSLBServer -Name $this.Name -IPAddress $this.IPAddress -Force -Verbose:$false
                }
                if ($server.comment -ne $this.Comments) {
                    Write-Verbose -Message "Setting server comments [$($this.Comments)]"
                    Set-NSLBServer -Name $this.Name -Comment $this.Comments -Force -Verbose:$false
                }
                if ($server.state -ne $this.State) { 
                    Write-Verbose -Message "Setting server state [$($this.State)]"
                    if ($this.State -eq 'ENABLED') {
                        Enable-NSLBServer -Name $this.Name -Force -Verbose:$false
                    } else {
                        Disable-NSLBServer -Name $this.Name -Force -Verbose:$false
                    }
                }
            } else {
                Write-Verbose -Message "Creating server [$($this.Name)]"
                $params = @{
                    Name = $this.Name
                    IPAddress = $this.IPAddress
                    Comment = $this.Comments
                    Confirm = $false
                    Verbose = $false
                }
                if ($null -ne $this.TrafficDomainId) {
                    $params.TrafficDomainId = $this.TrafficDomainId
                }
                New-NSLBServer @params
            }
            
        } catch {
            Write-Error 'There was a problem setting the resource'
            Write-Error "$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.InvocationInfo.Line)"
            Write-Error $_
        }
        try {
            Disconnect-NetScaler -Verbose:$false -ErrorAction SilentlyContinue
        } catch {
            # Do nothing
        }
    }

    [bool]Test() {

        $pass = $true

        [ref]$t = $null
        if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
            Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        } else {
            Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        }
        # Try to get the server
        $server = Get-NSLBServer -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue

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
        [ref]$t = $null
        if ([ipaddress]::TryParse($this.NetScalerFQDN,$t)) {
            Connect-NetScaler -IPAddress $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        } else {
            Connect-NetScaler -Hostname $this.NetScalerFQDN -Credential $this.Credential -Verbose:$false
        }

        $s = Get-NSLBServer -Name $this.Name -Verbose:$false -ErrorAction SilentlyContinue

        $obj = [LBServer]::new()
        $obj.Name = $this.Name
        $obj.IPAddress = $this.IPAddress
        $obj.Comments = $this.Comments
        $obj.TrafficDomainId = $this.TrafficDomainId
        $obj.State = $this.State
        $obj.Credential = $this.Credential
        $obj.NetScalerFQDN = $this.NetScalerFQDN
        $obj.ParameterExport = $this.ParameterExport
        if ($s) {
            $obj.Ensure = [ensure]::Present
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