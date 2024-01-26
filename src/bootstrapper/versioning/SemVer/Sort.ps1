param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader
)

& {
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name Sort `
        -Value {
            param( [string[]] $Versions, $Ascending = $true )

            $clone = $Versions.Clone()

            [Array]::Sort[string]( $clone, [System.Comparison[string]]({
                param($x, $y)
                $x = $Bootstrapper.SemVer.Parse( $x )
                $y = $Bootstrapper.SemVer.Parse( $y )

                $comparison = $Bootstrapper.SemVer.Compare( $x, $y )
                
                If( $Ascending ){
                    $comparison
                } Else {
                    $comparison * -1
                }
            }))

            $clone
        }
}