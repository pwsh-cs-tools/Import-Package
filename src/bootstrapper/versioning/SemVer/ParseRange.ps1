param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {

    # Parse a NuGet-spec version range
    # - see https://learn.microsoft.com/en-us/nuget/concepts/package-versioning?tabs=semver20sort
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ParseRange `
        -Value {
            param(
                [string] $Range,
                [string] $Name,
                [bool] $AllowPrerelease = $false
            )
            $Range = $Range.Trim()
            
            $parsed = @{
                MinVersion = $null
                MaxVersion = $null
                MinVersionInclusive = $null
                MaxVersionInclusive = $null
            }

            If( [string]::IsNullOrWhiteSpace( $Range ) ){
                Write-Verbose "[Import-Package:Internals(SemVer.ParseRange)] Blank range provided. Assuming [0.0.0, )"
                $parsed.MinVersion = "0.0.0"
                $parsed.MinVersionInclusive = $true
                $parsed.MaxVersion = $null
                $parsed.MaxVersionInclusive = $false
            } Else {
                $versions = $Range.Split( ',' )
                if( $versions.Count -eq 1 ){
                    if( $versions -match "[\[\(]" ){
                        $parsed.MinVersion = $versions[0].TrimStart( '[', '(' ).TrimEnd( ']', ')' )
                        $parsed.MinVersionInclusive = $true
                        $parsed.MaxVersion = $parsed.MinVersion
                        $parsed.MaxVersionInclusive = $true
                        If( $versions[0].StartsWith("(") -or $versions[0].EndsWith(")") ) {
                            If( $parsed.MinVersion ){
                                Write-Warning "[Import-Package:Internals(SemVer.ParseRange)] $Range is not a valid version range. Assuming exact version: [$( $parsed.MinVersion )]"
                            }
                        }
                    } else {
                        $parsed.MinVersion = $versions[0]
                        $parsed.MinVersionInclusive = $true
                        # $parsed.MaxVersion is unbounded
                    }
                } else {
                    if( $versions[0] -and ($versions[0] -match "[\[\(]") ){
                        $parsed.MinVersion = $versions[0].TrimStart( '[', '(' )
                        $parsed.MinVersionInclusive = $versions[0].StartsWith( '[' )
                    } else {
                        $parsed.MinVersion = $versions[0]
                        $parsed.MinVersionInclusive = $true
                    }
                    if( $versions[1] -and ($versions[1] -match "[\]\)]") ){
                        $parsed.MaxVersion = $versions[1].TrimEnd( ']', ')' )
                        $parsed.MaxVersionInclusive = $versions[1].EndsWith( ']' )
                    } else {
                        $parsed.MaxVersion = $versions[1]
                        $parsed.MaxVersionInclusive = $true
                    }
                }
    
                If( -not $parsed.MinVersion -and -not $parsed.MaxVersion ){
                    Write-Warning "[Import-Package:Internals(SemVer.ParseRange)] $Range is not a valid version range. Assuming [0.0.0, )"
                    $parsed.MinVersion = "0.0.0"
                    $parsed.MinVersionInclusive = $true
                    $parsed.MaxVersion = $null
                    $parsed.MaxVersionInclusive = $false
                }
    
                If( $parsed.MaxVersionInclusive -and -not $parsed.MaxVersion ){
                    Write-Warning "[Import-Package:Internals(SemVer.ParseRange)] $Range is not a valid version range. Assuming unbounded maximum version."
                    $parsed.MaxVersionInclusive = $false
                }
    
                If( $parsed.MinVersionInclusive -and -not $parsed.MinVersion ){
                    Write-Warning "[Import-Package:Internals(SemVer.ParseRange)] $Range is not a valid version range. Assuming unbounded minimum version."
                    $parsed.MinVersionInclusive = $false
                }
            }

            If( $parsed.MinVersion ){
                $parsed.MinVersion = $this.Parse( $parsed.MinVersion )
            }
            If( $parsed.MaxVersion ){
                $parsed.MaxVersion = $this.Parse( $parsed.MaxVersion )
            }

            $out_range = If( $Name ){

                $all_versions = $Bootstrapper.RemoteNupkg.GetAllVersions( $Name )
                $all_versions = $all_versions | ForEach-Object {
                    $this.Parse( $_ )
                }
    
                $effective_range = @{
                    MinVersion = $null
                    MaxVersion = $null
                    MinVersionInclusive = $true
                    MaxVersionInclusive = $true
                }
    
                If( -not $parsed.MaxVersion ){
                    $effective_range.MaxVersion = $all_versions | Where-Object {
                        If( $AllowPrerelease ){
                            $true
                        } Else {
                            -not $_.PreRelease -and -not $_.LegacyPrerelease
                        }
                    } | Select-Object -Last 1
                } Else {
                    $effective_range.MaxVersion = & {
                        $acceptable_versions = $all_versions | Where-Object {
                            If( $parsed.MaxVersionInclusive ){
                                $this.Compare( $_, $parsed.MaxVersion ) -le 0
                            } Else {
                                $this.Compare( $_, $parsed.MaxVersion ) -lt 0
                            }
                        } | Where-Object {
                            If( $AllowPrerelease ){
                                $true
                            } Else {
                                -not $_.PreRelease -and -not $_.LegacyPrerelease
                            }
                        }
                        $acceptable_versions | Select-Object -Last 1
                    }
                }
    
                If( -not $parsed.MinVersion ){
                    $effective_range.MinVersion = $all_versions | Where-Object {
                        If( $AllowPrerelease ){
                            $true
                        } Else {
                            -not $_.PreRelease -and -not $_.LegacyPrerelease
                        }
                    } | Select-Object -First 1
                } Else {
                    $effective_range.MinVersion = & {
                        $acceptable_versions = $all_versions | Where-Object {
                            If( $parsed.MinVersionInclusive ){
                                $this.Compare( $_, $parsed.MinVersion ) -ge 0
                            } Else {
                                $this.Compare( $_, $parsed.MinVersion ) -gt 0
                            }
                        } | Where-Object {
                            If( $AllowPrerelease ){
                                $true
                            } Else {
                                -not $_.PreRelease -and -not $_.LegacyPrerelease
                            }
                        }
                        $acceptable_versions | Select-Object -First 1
                    }
                }

                $effective_range
            } Else {
                $parsed
            }

            If( $out_range.MinVersion -and $out_range.MaxVersion ){
                switch( $this.Compare( $out_range.MinVersion, $out_range.MaxVersion ) ){
                    { $_ -gt 0 } {
                        Throw "[Import-Package:Internals(SemVer.ParseRange)] Invalid version range: $Range"
                    }
                    0 {
                        If( $out_range.MinVersionInclusive -and $out_range.MaxVersionInclusive ){
                            $this.ParseRange( "[$( $out_range.MinVersion.Original )]" )
                        } Else {
                            Throw "[Import-Package:Internals(SemVer.ParseRange)] Invalid version range: $Range"
                        }
                    }
                }
            }

            $out_range.Corrected = @(
                (& {
                    If( $out_range.MinVersionInclusive){ "[" } Else { "(" }
                }),
                $out_range.MinVersion.Original,
                ",",
                $out_range.MaxVersion.Original,
                (& {
                    If( $out_range.MaxVersionInclusive){ "]" } Else { ")" }
                })
            ) -join ""

            $out_range
        }
    
}