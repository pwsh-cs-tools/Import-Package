param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetAllVersions `
        -Value {
            param( $Name )
            $resource = $this.Endpoints.resources | Where-Object {
                $_."@type" -eq "PackageBaseAddress/3.0.0"
            }
            $id = $resource."@id"

            $versions = @(
                $id,
                $Name,
                "/index.json"
            ) -join ""

            $versions = Invoke-WebRequest $versions
            (ConvertFrom-Json $versions).versions
        }
}