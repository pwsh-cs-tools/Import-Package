param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader
)

& {
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ReduceRanges `
        -Value {
            param(
                [string] $RangeA,
                [string] $RangeB,
                [bool] $AllowPreRelease = $false,
                [string] $Name, [bool] $Upstream = $true
            )

            If( [string]::IsNullOrWhiteSpace( $RangeA ) -and [string]::IsNullOrWhiteSpace( $RangeB ) ){
                Throw "[Import-Package:Internals(SemVer.ReduceRanges)] Both ranges cannot be null or whitespace"
            } Elseif( [string]::IsNullOrWhiteSpace( $RangeA ) ){
                return $RangeB
            } Elseif ( [string]::IsNullOrWhiteSpace( $RangeB ) ){
                return $RangeA
            }

            $range_a = $this.ParseRange( $RangeA, $AllowPreRelease, $Name, $Upstream )
            $range_b = $this.ParseRange( $RangeB, $AllowPreRelease, $Name, $Upstream )

            $output_range = @{
                MinVersion = $null
                MaxVersion = $null
                MinVersionInclusive = $true
                MaxVersionInclusive = $true
            }

            If( (-not [string]::IsNullOrWhiteSpace( $range_a.MinVersion )) -and (-not [string]::IsNullOrWhiteSpace( $range_b.MinVersion )) ){
                $min_comparison = $this.Compare( $range_a.MinVersion, $range_b.MinVersion )
                switch( $min_comparison ){
                    { $_ -gt 0 } {
                        $output_range.MinVersion = $range_a.MinVersion
                        $output_range.MinVersionInclusive = $range_a.MinVersionInclusive
                    }
                    { $_ -lt 0 } {
                        $output_range.MinVersion = $range_b.MinVersion
                        $output_range.MinVersionInclusive = $range_b.MinVersionInclusive
                    }
                    { $_ -eq 0 } {
                        $output_range.MinVersion = $range_a.MinVersion
                        $output_range.MinVersionInclusive = $range_a.MinVersionInclusive -and $range_b.MinVersionInclusive
                    }
                }
            } Elseif( -not [string]::IsNullOrWhiteSpace( $range_a.MinVersion ) ){
                $output_range.MinVersion = $range_a.MinVersion
                $output_range.MinVersionInclusive = $range_a.MinVersionInclusive
            } Elseif( -not [string]::IsNullOrWhiteSpace( $range_b.MinVersion ) ){
                $output_range.MinVersion = $range_b.MinVersion
                $output_range.MinVersionInclusive = $range_b.MinVersionInclusive
            }

            If( (-not [string]::IsNullOrWhiteSpace( $range_a.MaxVersion )) -and (-not [string]::IsNullOrWhiteSpace( $range_b.MaxVersion )) ){
                $max_comparison = $this.Compare( $range_a.MaxVersion, $range_b.MaxVersion )
                switch( $max_comparison ){
                    { $_ -gt 0 } {
                        $output_range.MaxVersion = $range_b.MaxVersion
                        $output_range.MaxVersionInclusive = $range_b.MaxVersionInclusive
                    }
                    { $_ -lt 0 } {
                        $output_range.MaxVersion = $range_a.MaxVersion
                        $output_range.MaxVersionInclusive = $range_a.MaxVersionInclusive
                    }
                    { $_ -eq 0 } {
                        $output_range.MaxVersion = $range_a.MaxVersion
                        $output_range.MaxVersionInclusive = $range_a.MaxVersionInclusive -and $range_b.MaxVersionInclusive
                    }
                }
            } Elseif( -not [string]::IsNullOrWhiteSpace( $range_a.MaxVersion ) ){
                $output_range.MaxVersion = $range_a.MaxVersion
                $output_range.MaxVersionInclusive = $range_a.MaxVersionInclusive
            } Elseif( -not [string]::IsNullOrWhiteSpace( $range_b.MaxVersion ) ){
                $output_range.MaxVersion = $range_b.MaxVersion
                $output_range.MaxVersionInclusive = $range_b.MaxVersionInclusive
            }

            If( $output_range.MinVersion -and $output_range.MaxVersion ){
                switch( $this.Compare( $output_range.MinVersion, $output_range.MaxVersion ) ){
                    { $_ -gt 0 } {
                        Throw "[Import-Package:Internals(SemVer.ParseRange)] Invalid version range: $Range"
                    }
                    0 {
                        If( $output_range.MinVersionInclusive -and $output_range.MaxVersionInclusive ){
                            $this.ParseRange( "[$( $output_range.MinVersion.Original )]", $AllowPrerelease, $null, $false )
                        } Else {
                            Throw "[Import-Package:Internals(SemVer.ParseRange)] Invalid version range: $Range"
                        }
                    }
                }
            }

            $output_range.Corrected = @(
                (& {
                    If( $output_range.MinVersionInclusive){ "[" } Else { "(" }
                }),
                $output_range.MinVersion.Original,
                ",",
                $output_range.MaxVersion.Original,
                (& {
                    If( $output_range.MaxVersionInclusive){ "]" } Else { ")" }
                })
            ) -join ""

            $output_range
        }
}