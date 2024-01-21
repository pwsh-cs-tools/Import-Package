param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

# Semantic Versioning for SemVer 1 and 2
& {
    $semantic_versioning_reader = New-Object psobject
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name Parse `
        -Value {

            param(
                [string] $semVerString
            )
            
            If( [string]::IsNullOrWhiteSpace( $semVerString ) ){
                Throw "Name cannot be null or whitespace"
            }

            $semVerParts = $semVerString -split '[-\+]'
            If( $semVerParts.Count -gt 2 ){
                $semVerParts = @(
                    $semVerParts[0],
                    (($semVerParts | Select-Object -Skip 1) -join "-")
                )
            }
            $versionParts = $semVerParts[0] -split '\.'
        
            $versionParts = $versionParts | ForEach-Object {
                [int]$_
            }
        
            # Convert main version parts to integers
            $major = $versionParts[0]
            $minor = $versionParts[1]
            $patch = $versionParts[2]
            $legacyPrerelease = If( $versionParts.Count -gt 3 ){
                $versionParts[3..($versionParts.Length-1)]
            }
        
            $preRelease = $null
            if ($semVerParts.Length -gt 1) {
                $preRelease = $semVerParts[1]
            }
        
            # Create a custom object
            New-Object PSObject -Property @{
                Major = $major
                Minor = $minor
                Patch = $patch
                LegacyPrerelease = $legacyPrerelease
                PreRelease = $preRelease
                Original = $semVerString
            }
            
        }
    
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name Compare `
        -Value {
            param( $x, $y )
            if ($x.Major -ne $y.Major) {
                return $x.Major - $y.Major
            }
            if ($x.Minor -ne $y.Minor) {
                return $x.Minor - $y.Minor
            }
            if ($x.Patch -ne $y.Patch) {
                return $x.Patch - $y.Patch
            }
            if ($x.LegacyPrerelease -and $y.LegacyPrerelease){
                $max_length = [Math]::Max(
                    $x.LegacyPrerelease.Count,
                    $y.LegacyPrerelease.Count
                )
                for ($i = 0; $i -lt $max_length; $i++) {
                    $xlp = $x.LegacyPrerelease[ $i ]
                    $ylp = $y.LegacyPrerelease[ $i ]
                    If( $null -eq $xlp ){
                        return 1
                    }
                    If( $null -eq $ylp ){
                        return -1
                    }
                    If( $xlp -ne $ylp ){
                        return $xlp - $ylp
                    }
                }
            }
            # Handle pre-release comparison
            if ($x.PreRelease -and $y.PreRelease) {
                return [string]::Compare($x.PreRelease, $y.PreRelease)
            }
            if ($x.PreRelease) {
                return -1
            }
            if ($y.PreRelease) {
                return 1
            }
            return 0
        }

    # Parse a NuGet-spec version range
    # - see https://learn.microsoft.com/en-us/nuget/concepts/package-versioning?tabs=semver20sort
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ParseRange `
        -Value {
            param(
                [string] $Range,
                [string] $Name
            )
            $Range = $Range.Trim()
            
            $parsed = @{
                MinVersion = $null
                MaxVersion = $null
                MinVersionInclusive = $null
                MaxVersionInclusive = $null
            }

            If( [string]::IsNullOrWhiteSpace( $Range ) ){
                Write-Verbose "[Import-Package:Internals] Blank range provided. Assuming [0.0.0, )"
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
                                Write-Warning "[Import-Package:Internals] $Range is not a valid version range. Assuming exact version: [$( $parsed.MinVersion )]"
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
                    Write-Warning "[Import-Package:Internals] $Range is not a valid version range. Assuming [0.0.0, )"
                    $parsed.MinVersion = "0.0.0"
                    $parsed.MinVersionInclusive = $true
                    $parsed.MaxVersion = $null
                    $parsed.MaxVersionInclusive = $false
                }
    
                If( $parsed.MaxVersionInclusive -and -not $parsed.MaxVersion ){
                    Write-Warning "[Import-Package:Internals] $Range is not a valid version range. Assuming unbounded maximum version."
                    $parsed.MaxVersionInclusive = $false
                }
    
                If( $parsed.MinVersionInclusive -and -not $parsed.MinVersion ){
                    Write-Warning "[Import-Package:Internals] $Range is not a valid version range. Assuming unbounded minimum version."
                    $parsed.MinVersionInclusive = $false
                }
            }

            If( $parsed.MinVersion ){
                $parsed.MinVersion = $Bootstrapper.SemVer.Parse( $parsed.MinVersion )
            }
            If( $parsed.MaxVersion ){
                $parsed.MaxVersion = $Bootstrapper.SemVer.Parse( $parsed.MaxVersion )
            }

            $out_range = If( $Name ){

                $all_versions = $Bootstrapper.RemoteNupkg.GetAllVersions( $Name )
                $all_versions = $all_versions | ForEach-Object {
                    $Bootstrapper.SemVer.Parse( $_ )
                }
    
                $effective_range = @{
                    MinVersion = $null
                    MaxVersion = $null
                    MinVersionInclusive = $true
                    MaxVersionInclusive = $true
                }
    
                If( -not $parsed.MaxVersion ){
                    $effective_range.MaxVersion = $all_versions | Where-Object {
                        -not $_.PreRelease -and -not $_.LegacyPrerelease
                    } | Select-Object -Last 1
                } Else {
                    $effective_range.MaxVersion = & {
                        $acceptable_versions = $all_versions | Where-Object {
                            If( $parsed.MaxVersionInclusive ){
                                $Bootstrapper.SemVer.Compare( $_, $parsed.MaxVersion ) -le 0
                            } Else {
                                $Bootstrapper.SemVer.Compare( $_, $parsed.MaxVersion ) -lt 0
                            }
                        } | Where-Object {
                            -not $_.PreRelease -and -not $_.LegacyPrerelease
                        }
                        $acceptable_versions | Select-Object -Last 1
                    }
                }
    
                If( -not $parsed.MinVersion ){
                    $effective_range.MinVersion = $all_versions | Where-Object {
                        -not $_.PreRelease -and -not $_.LegacyPrerelease
                    } | Select-Object -First 1
                } Else {
                    $effective_range.MinVersion = & {
                        $acceptable_versions = $all_versions | Where-Object {
                            If( $parsed.MinVersionInclusive ){
                                $Bootstrapper.SemVer.Compare( $_, $parsed.MinVersion ) -ge 0
                            } Else {
                                $Bootstrapper.SemVer.Compare( $_, $parsed.MinVersion ) -gt 0
                            }
                        } | Where-Object {
                            -not $_.PreRelease -and -not $_.LegacyPrerelease
                        }
                        $acceptable_versions | Select-Object -First 1
                    }
                }

                $effective_range
            } Else {
                $parsed
            }

            If( $out_range.MinVersion -and $out_range.MaxVersion ){
                switch( $Bootstrapper.SemVer.Compare( $out_range.MinVersion, $out_range.MaxVersion ) ){
                    { $_ -gt 0 } {
                        throw "Invalid version range: $Range"
                    }
                    0 {
                        If( $out_range.MinVersionInclusive -and $out_range.MaxVersionInclusive ){
                            $this.ParseRange( "[$( $out_range.MinVersion.Original )]" )
                        } Else {
                            throw "Invalid version range: $Range"
                        }
                    }
                }
            }

            $out_range
        }

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name SemVer `
        -Value $semantic_versioning_reader
}