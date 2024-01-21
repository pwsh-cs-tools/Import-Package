param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

# NuGet Versioning APIs
& {

    $version_endpoints = New-Object psobject

    # Unused. Maintained for reference.
    $version_endpoints | Add-Member `
        -MemberType ScriptMethod `
        -Name SearchLatest `
        -Value {
            param( $Name )
            $resource = $Bootstrapper.NugetEndpoints.resources | Where-Object {
                ($_."@type" -eq "SearchQueryService") -and
                ($_.comment -like "*(primary)*")
            }
            $id = $resource."@id"

            $results = Invoke-WebRequest "$id`?q=packageid:$Name&prerelease=false&take=1"
            $results = ConvertFrom-Json $results

            If( $Name -eq $results.data[0].id ){
                $results.data[0].version
            } else {
                Write-Warning "Unable to find latest version of $Name via NuGet Search API"
            }
        }

    $version_endpoints | Add-Member `
        -MemberType ScriptMethod `
        -Name GetAllVersions `
        -Value {
            param( $Name )
            $resource = $Bootstrapper.NugetEndpoints.resources | Where-Object {
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

    $version_endpoints | Add-Member `
        -MemberType ScriptMethod `
        -Name GetPreRelease `
        -Value {
            param( $Name, $Wanted )

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

    $version_endpoints | Add-Member `
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

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name VersionEndpoints `
        -Value $version_endpoints
}