param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetDownloadUrl `
        -Value {
            param(
                [string] $Name,
                [string] $Verion
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "Name cannot be null or whitespace"
            }

            If( $Version -eq $null ) {
                $Version = $this.GetStable( $Name )
            }

            $resource = $this.Endpoints.resources | Where-Object {
                $_."@type" -eq "PackageBaseAddress/3.0.0"
            }
            $id = $resource."@id"

            @(
                $id,
                $Name, "/",
                "$Version", "/",
                "$Name.$Version.nupkg"
            ) -join ""
        }
}