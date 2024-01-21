param(
    [parameter(Mandatory = $true)]
    [psobject]
    $system_identifiers
)

& {
    $system_identifiers | Add-Member `
        -MemberType ScriptMethod `
        -Name GraphRuntimes `
        -Value {
            param(
                [string] $RuntimeIdentifier,
                [System.Collections.ArrayList] $Graph,
                [System.Collections.ArrayList] $Graphs
            )
        
            if( $RuntimeIdentifier ){
                $Graph.Add( $RuntimeIdentifier ) | Out-Null
        
                $kids = $this.Runtimes."$RuntimeIdentifier".'#import'
                If( $kids.Count -gt 0 ){
                    $kids | Select-Object -Skip 1 | ForEach-Object {
                        $clone = $Graph.Clone()
                        $Graphs.Add( $clone ) | Out-Null
                        $this.GraphRuntimes( $_, $clone, $Graphs )
                    }
                }
                $this.GraphRuntimes( $kids[0], $Graph, $Graphs )
            }
        }
}