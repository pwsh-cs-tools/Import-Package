param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader
)

& {
    # This may warrant refactoring ParseRange.Corrected

    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name LimitVersions `
        -Value {
            param(
                [string[]] $Versions,
                [string] $Range
            )

            If( [string]::IsNullOrWhiteSpace( $Range ) ){
                Throw "[Import-Package:Internals(SemVer.LimitVersions)] Range cannot be null or whitespace"
            }

            If( $Versions.Count -eq 0 ){
                return $Versions
            }
            
            $parsed_range = $this.ParseRange( $Range )
            
            $Versions | Where-Object{
                $parsed = $this.Parse( $_ )

                $lower_bound_comparison = $this.Compare( $parsed, $parsed_range.MinVersion )
                $upper_bound_comparison = $this.Compare( $parsed, $parsed_range.MaxVersion )

                $IsGreaterThanOrEqualToMin = $lower_bound_comparison -ge 0
                $IsGreaterThanMin = $lower_bound_comparison -gt 0
                $IsLessThanOrEqualToMax = $upper_bound_comparison -le 0
                $IsLessThanMax = $upper_bound_comparison -lt 0

                $IsLowerThanUpperBound = @(
                    ($parsed_range.MaxVersionInclusive -and $IsLessThanOrEqualToMax),
                    (-not $parsed_range.MaxVersionInclusive -and $IsLessThanMax)
                ) -contains $true
                $IsHigherThanLowerBound = @(
                    ($parsed_range.MinVersionInclusive -and $IsGreaterThanOrEqualToMin),
                    (-not $parsed_range.MinVersionInclusive -and $IsGreaterThanMin)
                ) -contains $true

                $IsLowerThanUpperBound -and $IsHigherThanLowerBound
            }
        }
}