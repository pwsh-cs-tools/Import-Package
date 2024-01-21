param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $remote_nupkg_reader = New-Object psobject

    # $remote_nupkg_reader.Endpoints
    & "$PSScriptRoot/RemoteNupkg/Endpoints.ps1" $remote_nupkg_reader | Out-Null
    # $remote_nupkg_reader.GetDownloadUrl()
    & "$PSScriptRoot/RemoteNupkg/GetDownloadUrl.ps1" $remote_nupkg_reader | Out-Null

    # $remote_nupkg_reader.SearchLatest()
    & "$PSScriptRoot/RemoteNupkg/SearchLatest.ps1" $remote_nupkg_reader | Out-Null

    # Required for Package Reader:

    # $remote_nupkg_reader.GetAllVersions()
    & "$PSScriptRoot/RemoteNupkg/GetAllVersions.ps1" $remote_nupkg_reader $Bootstrapper | Out-Null
    # $remote_nupkg_reader.GetPreRelease()
    & "$PSScriptRoot/RemoteNupkg/GetPreRelease.ps1" $remote_nupkg_reader | Out-Null
    # $remote_nupkg_reader.GetStable()
    & "$PSScriptRoot/RemoteNupkg/GetStable.ps1" $remote_nupkg_reader | Out-Null

    # $remote_nupkg_reader.ListEntries()
    & "$PSScriptRoot/RemoteNupkg/ListEntries.ps1" $remote_nupkg_reader $Bootstrapper | Out-Null
    # $remote_nupkg_reader.ReadNuspec()
    & "$PSScriptRoot/RemoteNupkg/ReadNuspec.ps1" $remote_nupkg_reader | Out-Null

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name RemoteNupkg `
        -Value $remote_nupkg_reader
}