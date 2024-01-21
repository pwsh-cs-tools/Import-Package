& {
    Add-Type -AssemblyName System.Runtime # Useful for RID detection
    Add-Type -AssemblyName System.IO.Compression.FileSystem # Useful for reading nupkg/zip files

    $Bootstrapper = New-Object psobject

    # $Bootstrapper.ReadNuspecFromNupkg()
    & "$PSScriptRoot/data/ReadNuspecFromNupkg.ps1" $Bootstrapper | Out-Null
    
    # $Bootstrapper.LoadManaged()
    & "$PSScriptRoot/loading/LoadManaged.ps1" $Bootstrapper | Out-Null

    # $Bootstrapper.InternalLibraries
    & "$PSScriptRoot/init/InternalLibraries.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.InternalPackages and $Bootstrapper.InternalPackagesOrder
    & "$PSScriptRoot/init/InternalPackages.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.AreLibsInitialized()
    & "$PSScriptRoot/init/AreLibsInitialized.ps1" $Bootstrapper | Out-Null

    $Bootstrapper
}