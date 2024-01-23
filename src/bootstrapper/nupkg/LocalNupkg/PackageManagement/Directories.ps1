param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_package_manager,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_package_manager | Add-Member `
        -MemberType NoteProperty `
        -Name Directories `
        -Value (& {
            $directories = @{}

            # see: https://github.com/OneGet/oneget/blob/WIP/src/Microsoft.PackageManagement/Implementation/PackageManagementService.cs#L149-L195
            $basepaths = @{}

            If( [Environment]::SpecialFolder ){
                $basepaths.User = [Environment]::GetFolderPath( [Environment+SpecialFolder]::LocalApplicationData )
                $basepaths.System = [Environment]::GetFolderPath( [Environment+SpecialFolder]::ProgramFiles )
            } Else {
                $basepaths.User = [Environment]::GetFolderPath( "LocalApplicationData" )
                $basepaths.System = [Environment]::GetFolderPath( "ProgramFiles" )
            }

            $directories.User = Join-Path $basepaths.User "PackageManagement\NuGet\Packages"
            $directories.System = Join-Path $basepaths.System "PackageManagement\NuGet\Packages"
            
            $directories.Fallback = Join-Path $Bootstrapper.Root "Packages"
            $directories.Patches = Join-Path $Bootstrapper.Root "Patches"

            $directories
        })
}