param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $system_identifiers = New-Object psobject
    # $system_identifiers.Framework
    & "$PSScriptRoot/Framework.ps1" $system_identifiers $Bootstrapper
    # $system_identifiers.Runtimes
    # & "$PSScriptRoot/Runtimes.ps1" $system_identifiers $Bootstrapper

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name System `
        -Value $system_identifiers
}