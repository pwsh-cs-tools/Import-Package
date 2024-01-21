& {
    Add-Type -AssemblyName System.Runtime # Useful for RID detection
    Add-Type -AssemblyName System.IO.Compression.FileSystem # Useful for reading nupkg/zip files

    $Bootstrapper = New-Object psobject

    # $Bootstrapper.ReadNuspecFromNupkg()
    & "$PSScriptRoot/data/ReadNuspecFromNupkg.ps1" $Bootstrapper | Out-Null
    # $Bootstrapper.LoadManaged()
    & "$PSScriptRoot/loading/LoadManaged.ps1" $Bootstrapper | Out-Null

    $Bootstrapper
}