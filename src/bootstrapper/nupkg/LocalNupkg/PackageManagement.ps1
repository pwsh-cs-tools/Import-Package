param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_nupkg_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_package_manager = New-Object psobject

    & "$PSScriptRoot/PackageManagement/Directories.ps1" $local_package_manager $Bootstrapper | Out-Null
    & "$PSScriptRoot/PackageManagement/GetFromCache.ps1" $local_package_manager $Bootstrapper | Out-Null
    & "$PSScriptRoot/PackageManagement/GetFromMain.ps1" $local_package_manager | Out-Null
    & "$PSScriptRoot/PackageManagement/GetFromPatches.ps1" $local_package_manager | Out-Null
    & "$PSScriptRoot/PackageManagement/SelectBest.ps1" $local_package_manager $Bootstrapper | Out-Null

    $local_nupkg_reader | Add-Member `
        -MemberType NoteProperty `
        -Name PackageManagement `
        -Value $local_package_manager
}