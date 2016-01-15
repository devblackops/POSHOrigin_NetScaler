@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'POSHOrigin_NetScaler.psm1'

    # Version number of this module.
    ModuleVersion = '1.1.2'

    # ID used to uniquely identify this module
    GUID = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'

    # Author of this module
    Author = 'Brandon Olin'

    # Copyright statement for this module
    Copyright = '(c) 2015 Brandon Olin. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'POSHOrigin DSC module to manage Citrix NetScaler resources.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = 'NetScaler'

    # DSC resources to export from this module
    DscResourcesToExport = @('LBVirtualServer', 'LBServer')

    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @(
                'Desired State Configuration',
                'DSC',
                'POSHOrigin',
                'Citrix',
                'NetScaler',
                'Load balancing',
                'Infrastructure as Code',
                'IaC'
            )
        }
    }
}