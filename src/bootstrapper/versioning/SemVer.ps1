param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

# Semantic Versioning for SemVer 1 and 2
& {
    $semantic_versioning_reader = New-Object psobject
    & "$PSScriptRoot/SemVer/Parse.ps1" $semantic_versioning_reader | Out-Null
    & "$PSScriptRoot/SemVer/Compare.ps1" $semantic_versioning_reader | Out-Null
    & "$PSScriptRoot/SemVer/ParseRange.ps1" $semantic_versioning_reader $Bootstrapper | Out-Null
    & "$PSScriptRoot/SemVer/ReduceRanges.ps1" $semantic_versioning_reader | Out-Null
    & "$PSScriptRoot/SemVer/LimitVersions.ps1" $semantic_versioning_reader | Out-Null

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name SemVer `
        -Value $semantic_versioning_reader
}