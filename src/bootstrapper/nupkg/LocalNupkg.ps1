param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_nupkg_reader = New-Object psobject

    # $local_nupkg_reader.PackageManagement
    & "$PSScriptRoot/LocalNupkg/PackageManagement.ps1" $local_nupkg_reader $Bootstrapper | Out-Null

    # Required for Package Reader:
    
    # $local_nupkg_reader.GetAllVersions()
    & "$PSScriptRoot/LocalNupkg/GetAllVersions.ps1" $local_nupkg_reader $Bootstrapper | Out-Null
    # $local_nupkg_reader.GetPreRelease()
    & "$PSScriptRoot/LocalNupkg/GetPreRelease.ps1" $local_nupkg_reader | Out-Null
    # $local_nupkg_reader.GetStable()
    & "$PSScriptRoot/LocalNupkg/GetStable.ps1" $local_nupkg_reader $Bootstrapper | Out-Null
    
    # $local_nupkg_reader.ListEntries()
    & "$PSScriptRoot/LocalNupkg/ListEntries.ps1" $local_nupkg_reader $Bootstrapper | Out-Null
    # $local_nupkg_reader.ReadNuspec()
    & "$PSScriptRoot/LocalNupkg/ReadNuspec.ps1" $local_nupkg_reader $Bootstrapper | Out-Null

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name LocalNupkg `
        -Value $local_nupkg_reader
}