param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType NoteProperty `
        -Name Endpoints `
        -Value (& {
            $apis = Invoke-WebRequest https://api.nuget.org/v3/index.json
            ConvertFrom-Json $apis
        })
}