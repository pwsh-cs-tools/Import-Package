param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $remote_nupkg_reader = New-Object psobject

    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetDownloadUrl `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string] $Verion
            )

            If( $Version -eq $null ) {
                $Version = $Bootstrapper.VersionEndpoints.GetStable( $Name )
            }

            $resource = $Bootstrapper.NugetEndpoints.resources | Where-Object {
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
    
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ListEntries `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string] $Verion
            )

            $url = $this.GetDownloadUrl( $Name, $Version )

            $Bootstrapper.MiniZip.GetRemoteZipEntries( $url )
        }

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
                $Version = $Bootstrapper.VersionEndpoints.GetStable( $Name )
            }

            $resource = $Bootstrapper.NugetEndpoints.resources | Where-Object {
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

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name RemoteNupkg `
        -Value $remote_nupkg_reader
}