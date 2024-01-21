param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetStable `
        -Value {
            param( $Name, $Wanted )
            
            $version = $this.GetAllVersions( $Name ) | Where-Object {
                $parsed = $Bootstrapper.Semver.Parse( $_ )

                -not( $parsed.PreRelease <# -or $parsed.LegacyPrerelease #> )
            } | Where-Object {
                If( $Wanted ){
                    $_ -eq $Wanted
                } Else {
                    $true
                }
            } | Select-Object -Last 1

            If( $version ){
                $version
            } else {
                # if this is the case, Import-Package will default to GetPrerelease
                Write-Warning "Unable to find stable version of $Name$( If( $Wanted ){ " under version $Wanted" } )"
            }
        }
}