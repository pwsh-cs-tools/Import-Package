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
    # $Bootstrapper.Init()
    & "$PSScriptRoot/init/Init.ps1" $Bootstrapper | Out-Null

    $Bootstrapper.Init()

    <#
        # Used for reading framework information from nupkgs and nuspecs

        $Bootstrapper.Nuget:
        - $Bootstrapper.Nuget.Frameworks
        - $Bootstrapper.Nuget.Reducer
    #>
    & "$PSScriptRoot/package_apis/Nuget.ps1" $Bootstrapper | Out-Null

    <#
        # Used for reading nupkg contents remotely with low latency

        $Bootstrapper.MiniZip:
        - $Bootstrapper.MiniZip.RemoteZipReaderFactory
        - $Bootstrapper.MiniZip.GetRemoteZipEntries()
    #>
    & "$PSScriptRoot/package_apis/MiniZip.ps1" $Bootstrapper | Out-Null


    # Refactor Bootstrapper.System after runtimeidentifiers.ps1 is refactored

    $Bootstrapper
}