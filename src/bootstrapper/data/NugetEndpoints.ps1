param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name NugetEndpoints `
        -Value (& {
            $apis = Invoke-WebRequest https://api.nuget.org/v3/index.json
            ConvertFrom-Json $apis
        })
}