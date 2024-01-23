param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ReadNuspec `
        -Value {
            param(
                [string] $Name,
                [string] $Verion
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(RemoteNupkg.ReadNuspec)] Name cannot be null or whitespace"
            }

            $Version = If( [string]::IsNullOrWhiteSpace( $Version ) ){
                $latest_stable = $this.GetStable( $Name )
                If( [string]::IsNullOrWhiteSpace( $latest_stable ) ){
                    $this.GetPreRelease( $Name )
                } Else {
                    $latest_stable
                }
            } Else {
                $Version
            }

            $resource = $this.Endpoints.resources | Where-Object {
                $_."@type" -eq "PackageBaseAddress/3.0.0"
            }
            $id = $resource."@id"

            $url = @(
                $id,
                $Name, "/",
                "$Version", "/",
                "$Name.nuspec"
            ) -join ""

            $result = Invoke-WebRequest $url
            [xml]$result.Content
        }
}