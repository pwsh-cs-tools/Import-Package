& {
    Add-Type -AssemblyName System.Runtime # Useful for RID detection
    Add-Type -AssemblyName System.IO.Compression.FileSystem # Useful for reading nupkg/zip files

    $Bootstrapper = New-Object psobject

    <#
        # Used for reading data from local nupkgs

        $Bootstrapper.LocalNupkg:
        - $Bootstrapper.LocalNupkg.ListEntries()
        - $Bootstrapper.LocalNupkg.ReadNuspec()
    #>
    & "$PSScriptRoot/data/LocalNupkg.ps1" $Bootstrapper | Out-Null

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

    <#
        $Bootstrapper.SemVer:
        - $Bootstrapper.SemVer.Parse()
        - $Bootstrapper.SemVer.Compare()
    #>
    & "$PSScriptRoot/data/SemVer.ps1" $Bootstrapper | Out-Null
    
    # $Bootstrapper.NugetEndpoints
    & "$PSScriptRoot/data/NugetEndpoints.ps1" $Bootstrapper | Out-Null
    <#
        $Bootstrapper.VersionEndpoints:
        - $Bootstrapper.VersionEndpoints.SearchLatest()
        - $Bootstrapper.VersionEndpoints.GetAllVersions()
        - $Bootstrapper.VersionEndpoints.GetPreRelease()
        - $Bootstrapper.VersionEndpoints.GetStable()
    #>
    & "$PSScriptRoot/data/VersionEndpoints.ps1" $Bootstrapper | Out-Null

    <#
        # Used for reading data from remote nupkgs (on NuGet.org)

        $Bootstrapper.RemoteNupkg:
        - $Bootstrapper.RemoteNupkg.ListEntries()
        - $Bootstrapper.RemoteNupkg.ReadNuspec()
    #>
    & "$PSScriptRoot/data/RemoteNupkg.ps1" $Bootstrapper | Out-Null


    # Refactor Bootstrapper.System after runtimeidentifiers.ps1 is refactored

    $Bootstrapper
}