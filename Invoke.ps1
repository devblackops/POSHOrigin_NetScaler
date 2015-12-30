<#
    This script expects to be passed a psobject with all the needed properties
    in order to invoke 'NetScaler' DSC resources.
#>
[cmdletbinding()]
param(
    [parameter(mandatory)]
    [psobject]$Options,

    [bool]$Direct = $false
)

# Ensure we have a valid 'ensure' property
if ($null -eq $Options.options.Ensure) {
    $Options.Options | Add-Member -MemberType NoteProperty -Name Ensure -Value 'Present' -Force
}

# Get the resource type
$type = $Options.Resource.split(':')[1]

$hash = @{
    Name = $Options.Name
    Ensure = $Options.options.Ensure
    Credential = $Options.Options.Adminuser.Credential
    NetScalerFQDN = $Options.Options.NetScalerFQDN
}

$export = $false
if ($Options.options.ParameterExport) {
    $export = [bool]$Options.options.ParameterExport
}

switch ($type) {
    'LBServer' {
        if ($Direct) {
            $hash.IPAddress = $Options.Options.IPAddress
            $hash.Comments = $Options.Options.Description
            $hash.TrafficDomainId = $Options.Options.TrafficDomainId
            $hash.State = $Options.Options.State
            $hash.ParameterExport = $export
            return $hash
        } else {
            $confName = "$type" + '_' + $Options.Name
            Write-Verbose -Message "Returning configuration function for resource: $confName"
            Configuration $confName {
                Param (
                    [psobject]$ResourceOptions
                )

                Import-DscResource -Name LBServer -ModuleName POSHOrigin_NetScaler

                if (-Not $ResourceOptions.options.State) {
                    $ResourceOptions.options | Add-Member -MemberType NoteProperty -Name State -Value 'ENABLED'
                }

                LBServer $ResourceOptions.Name {
                    Ensure = $ResourceOptions.options.Ensure
                    Name = $ResourceOptions.Name
                    NetScalerFQDN = $ResourceOptions.options.netscalerfqdn
                    Credential = $ResourceOptions.options.secrets.AdminUser.Credential
                    IPAddress = $ResourceOptions.options.IPAddress
                    TrafficDomainId = $ResourceOptions.options.TrafficDomainId
                    Comments = $ResourceOptions.description
                    State = $ResourceOptions.options.State
                    ParameterExport = $export
                }
            }
        }
    }
    'LBVirtualServer' {
        if ($Direct) {
            $hash.IPAddress = $Options.Options.IPAddress
            $hash.Port = $Options.Options.Port
            $hash.LBMethod = $Options.Options.LBMethod
            $hash.Comments = $Options.Options.Description
            $hash.State = $Options.Options.State
            $hash.ParameterExport = $export
            return $hash
        } else {
            $confName = "$type" + '_' + $Options.Name
            Write-Verbose -Message "Returning configuration function for resource: $confName"
            Configuration $confName {
                Param (
                    [psobject]$ResourceOptions
                )

                Import-DscResource -Name LBVirtualServer -ModuleName POSHOrigin_NetScaler

                if (-Not $ResourceOptions.options.State) {
                    $ResourceOptions.options | Add-Member -MemberType NoteProperty -Name State -Value 'ENABLED'
                }

                LBVirtualServer $ResourceOptions.Name {
                    Ensure = $ResourceOptions.options.Ensure
                    Name = $ResourceOptions.Name
                    NetScalerFQDN = $ResourceOptions.options.netscalerfqdn
                    Credential = $ResourceOptions.options.secrets.AdminUser.Credential
                    IPAddress = $ResourceOptions.options.IPAddress
                    Port = $ResourceOptions.options.Port
                    ServiceType = $ResourceOptions.options.servicetype
                    LBMethod = $ResourceOptions.options.lbmethod
                    Comments = $ResourceOptions.description
                    State = $ResourceOptions.options.State
                    ParameterExport = $export
                }
            }
        }
    }
}