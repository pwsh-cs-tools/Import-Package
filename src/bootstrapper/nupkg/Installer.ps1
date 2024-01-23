param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name Install `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [ValidateSet(
                    "PackageManagement",   "PM",
                    "Cache", "SemVer2",    "SV", "SV2",
                    "Patches",             "P"
                )]
                [string]
                $Destination,
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string]
                $Version
            )

            $Destination = Switch( $Destination ){
                "PM" { "PackageManagement" }
                "SemVer2" { "Cache" }
                "SV" { "Cache" }
                "SV2" { "Cache" }
                "P" { "Patches" }
                Default { $Destination }
            }

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(InstallNupkg)] Name cannot be null or whitespace"
            }

            $Version = If( [string]::IsNullOrWhiteSpace( $Version ) ){
                $latest_stable = $Bootstrapper.RemoteNupkg.GetStable( $Name )
                If( [string]::IsNullOrWhiteSpace( $latest_stable ) ){
                    $Bootstrapper.RemoteNupkg.GetPreRelease( $Name )
                } Else {
                    $latest_stable
                }
            } Else {
                $Version
            }

            If( [string]::IsNullOrWhiteSpace( $Version ) ){
                Throw "[Import-Package:Internals(InstallNupkg)] Version cannot be null or whitespace"
            }

            # PackageManagement does not support SemVer2
            If( -not [string]::IsNullOrWhiteSpace( $Version ) -and $Destination -eq "PackageManagement" ){
                $parsed_version = $Bootstrapper.SemVer.Parse( $Version )
                If( $parsed_version.Prerelease ){
                    Write-Warning "[Import-Package:Internals(InstallNupkg)] $Name $Version is a SemVer2 prerelease version. Installing to Cache instead of PackageManagement."
                    $Destination = "Cache"
                }
            }

            switch( $Destination ){
                "PackageManagement" {
                    $package = $Bootstrapper.LocalNupkg.PackageManagement.GetFromMain( $Name, $Version )
                    If( $package.Count -eq 0 ){
                        Try {
                            Install-Package $Name `
                                -RequiredVersion $Version `
                                -ProviderName NuGet `
                                -SkipDependencies `
                                -Force `
                                -ErrorAction Stop | Out-Null
                        } Catch {        
                            Install-Package $Name `
                                -RequiredVersion $Version `
                                -ProviderName NuGet `
                                -SkipDependencies `
                                -Scope CurrentUser `
                                -Force | Out-Null
                        }
                        $Bootstrapper.LocalNupkg.PackageManagement.GetFromMain( $Name, $Version )
                    } Else {
                        $package
                        Write-Verbose "[Import-Package:Internals(InstallNupkg)] $Name $Version already installed by PackageManagement"
                    }
                }
                Default {
                    $download_url = $Bootstrapper.RemoteNupkg.GetDownloadUrl( $Name, $Version )
                    $packages_path = $Bootstrapper.LocalNupkg.PackageManagement.Directories[ $Destination ]
                    $parent_path = Join-Path $packages_path "$Name.$Version"
                    $path = Join-Path $parent_path "$Name.$Version.nupkg"

                    If( Test-Path $parent_path ){
                        If( Test-Path $path ){
                            Write-Verbose "[Import-Package:Internals(InstallNupkg)] $Name $Version already installed to $Destination"
                            If( $Destination -eq "Cache" ){
                                $Bootstrapper.LocalNupkg.PackageManagement.GetFromCache( $Name, $Version )
                            } ElseIf( $Destination -eq "Patches" ){
                                $Bootstrapper.LocalNupkg.PackageManagement.GetFromPatches( $Name, $Version )
                            }
                            return
                        }
                    } Else {
                        New-Item -ItemType Directory -Path $parent_path | Out-Null
                    }

                    Invoke-WebRequest $download_url -OutFile $path
                    [System.IO.Compression.ZipFile]::ExtractToDirectory( $path, $parent_path, $true ) | Out-Null

                    If( $Destination -eq "Cache" ){
                        $Bootstrapper.LocalNupkg.PackageManagement.GetFromCache( $Name, $Version )
                    } ElseIf( $Destination -eq "Patches" ){
                        $Bootstrapper.LocalNupkg.PackageManagement.GetFromPatches( $Name, $Version )
                    }
                }
            }
        }

    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name Ensure `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string]
                $Version
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(EnsureNupkg)] Name cannot be null or whitespace"
            }

            $package = $Bootstrapper.LocalNupkg.PackageManagement.SelectBest( $Name, $Version )
            # We no longer autoupdate the internal packages on the init process

            If( -not $package ){
                $package = $Bootstrapper.Install( "PackageManagement", $Name, $Version )
            }

            If( -not $package ){
                Throw "[Import-Package:Internals(InternalPackages)] Could not find required package $Name$(
                    If( -not [string]::IsNullOrWhiteSpace( $Version ) ){ " under version $Version"
                } )"
            }

            $package
        }
}