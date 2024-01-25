param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetPreRelease `
        -Value {
            param( $Name, $Wanted )
            
            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(RemoteNupkg.GetPrerelease)] Name cannot be null or whitespace"
            }

            $versions = $this.GetAllVersions( $Name )

            If( $Wanted ){
                $out = $versions | Where-Object {
                    $_ -eq $Wanted
                }
                If( $out ){
                    $out
                } Else {
                    $versions | Select-Object -last 1
                }
            } Else {
                $versions | Select-Object -last 1
            }
        }
}