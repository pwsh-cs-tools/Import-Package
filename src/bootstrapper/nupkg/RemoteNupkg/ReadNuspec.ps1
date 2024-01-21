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
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string] $Verion
            )

            If( $Version -eq $null ) {
                $Version = $this.GetStable( $Name )
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