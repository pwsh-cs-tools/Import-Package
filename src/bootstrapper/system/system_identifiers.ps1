param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $system_identifiers = New-Object psobject
    # $system_identifiers.GraphRuntimes
    & "$PSScriptRoot/GraphRuntimes.ps1" $system_identifiers
    # $system_identifiers.Framework
    & "$PSScriptRoot/Framework.ps1" $system_identifiers $Bootstrapper
    # $system_identifiers.Runtimes and $system_identifiers.Runtime
    & "$PSScriptRoot/Runtimes.ps1" $system_identifiers
    # $system_identifiers.RuntimeGraphs
    & "$PSScriptRoot/RuntimeGraphs.ps1" $system_identifiers

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name System `
        -Value $system_identifiers
}