param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader
)

& {
    
    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name Compare `
        -Value {
            param( $x, $y )

            If( $x.GetType() -eq [string] ){
                $x = $this.Parse( $x )
            }
            If( $y.GetType() -eq [string] ){
                $y = $this.Parse( $y )
            }

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
    
}