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
        -Name ListEntries `
        -Value {
            param(
                [string] $Name,
                [string] $Verion
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(RemoteNupkg.ListEntries)] Name cannot be null or whitespace"
            }

            $url = $this.GetDownloadUrl( $Name, $Version )

            $Bootstrapper.MiniZip.GetRemoteZipEntries( $url )
        }
}