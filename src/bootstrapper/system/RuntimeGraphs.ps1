param(
    [parameter(Mandatory = $true)]
    [psobject]
    $system_identifiers
)

& {
    $system_identifiers | Add-Member `
        -MemberType NoteProperty `
        -Name RuntimeGraphs `
        -Value (New-Object System.Collections.ArrayList)

    $system_identifiers.RuntimeGraphs.Add( (New-Object System.Collections.ArrayList) ) | Out-Null

    $system_identifiers.GraphRuntimes(
        $system_identifiers.Runtime,
        $system_identifiers.RuntimeGraphs[0],
        $system_identifiers.RuntimeGraphs
    )
        
}