& {
    Add-Type -AssemblyName System.Runtime # Useful for RID detection
    Add-Type -AssemblyName System.IO.Compression.FileSystem # Useful for reading nupkg/zip files

    $Bootstrapper = New-Object psobject

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name Root `
        -Value (Resolve-Path "$PSScriptRoot/../..").Path

    & "$PSScriptRoot/csharp/csharp.ps1" $Bootstrapper | Out-Null

    <#
        $Bootstrapper.SemVer:
        - $Bootstrapper.SemVer.Parse()
        - $Bootstrapper.SemVer.ParseRange() # NuGet-spec version ranges
        - $Bootstrapper.SemVer.Compare()
    #>
    & "$PSScriptRoot/versioning/SemVer.ps1" $Bootstrapper | Out-Null

    <#
        # Used for reading data from local nupkgs

        $Bootstrapper.LocalNupkg:
        - $Bootstrapper.LocalNupkg.ListEntries()
        - $Bootstrapper.LocalNupkg.ReadNuspec()
        - $Bootstrapper.LocalNupkg.PackageManagement:
            - $Bootstrapper.LocalNupkg.PackageManagement.Directories
            - $Bootstrapper.LocalNupkg.PackageManagement.GetFromCache()
            - $Bootstrapper.LocalNupkg.PackageManagement.GetFromMain()
            - $Bootstrapper.LocalNupkg.PackageManagement.GetFromPatches()
            - $Bootstrapper.LocalNupkg.PackageManagement.SelectBest()
    #>
    & "$PSScriptRoot/nupkg/LocalNupkg.ps1" $Bootstrapper | Out-Null

    <#
        # Used for reading data from remote nupkgs (on NuGet.org)

        $Bootstrapper.RemoteNupkg:
        - $Bootstrapper.RemoteNupkg.Endpoints
        - $Bootstrapper.RemoteNupkg.GetDownloadUrl()
        - $Bootstrapper.RemoteNupkg.GetAllVersions()
        - $Bootstrapper.RemoteNupkg.GetPreRelease()
        - $Bootstrapper.RemoteNupkg.GetStable()
        - $Bootstrapper.RemoteNupkg.SearchLatest()
        - **$Bootstrapper.RemoteNupkg.ListEntries()
          - **: Requires MiniZip to be loaded (see below)
        - $Bootstrapper.RemoteNupkg.ReadNuspec()
    #>
    & "$PSScriptRoot/nupkg/RemoteNupkg.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.Install() and $Bootstrapper.Ensure()
    & "$PSScriptRoot/nupkg/Installer.ps1" $Bootstrapper | Out-Null

    # $Bootstrapper.LoadManaged()
    & "$PSScriptRoot/loading/LoadManaged.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.TestNative() and $Bootstrapper.LoadNative()
    & "$PSScriptRoot/loading/LoadNative.ps1" $Bootstrapper | Out-Null

    # $Bootstrapper.InternalLibraries
    & "$PSScriptRoot/init/InternalLibraries.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.InternalPackages and $Bootstrapper.InternalPackagesOrder
    & "$PSScriptRoot/init/InternalPackages.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.AreLibsInitialized()
    & "$PSScriptRoot/init/AreLibsInitialized.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.Init()
    & "$PSScriptRoot/init/Init.ps1" $Bootstrapper | Out-Null

    If( $Bootstrapper.AreLibsInitialized() -eq $false ){
        $Bootstrapper.Init()
    } Else {
        Write-Warning "[Import-Package:Internals] Import-Package may have already been initialized."
    }

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
        $Bootstrapper.System:
        - $Bootstrapper.System.Framework
        - $Bootstrapper.System.GraphRuntimes()
        - $Bootstrapper.System.Runtimes
        - $Bootstrapper.System.Runtime
        - $Bootstrapper.System.RuntimeGraphs
    #>
    & "$PSScriptRoot/system/system_identifiers.ps1" $Bootstrapper | Out-Null
    
    # $Bootstrapper.GetPlatformFolders()
    & "$PSScriptRoot/dependencies/platforms.ps1" $Bootstrapper | Out-Null

    # Refactor Bootstrapper.System after runtimeidentifiers.ps1 is refactored

    $Bootstrapper
}