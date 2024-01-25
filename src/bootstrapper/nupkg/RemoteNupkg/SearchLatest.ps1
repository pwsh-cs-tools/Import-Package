param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name SearchLatest `
        -Value {
            param( $Name )
            
            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(RemoteNupkg.SearchLatest)] Name cannot be null or whitespace"
            }

            $resource = $this.Endpoints.resources | Where-Object {
                ($_."@type" -eq "SearchQueryService") -and
                ($_.comment -like "*(primary)*")
            }
            $id = $resource."@id"

            $results = Invoke-WebRequest "$id`?q=packageid:$Name&prerelease=false&take=1"
            $results = ConvertFrom-Json $results

            If( $Name -eq $results.data[0].id ){
                $results.data[0].version
            } else {
                Write-Warning "[Import-Package:Internals(RemoteNupkg.SearchLatest)] Unable to find latest version of $Name via NuGet Search API"
            }
        }
}