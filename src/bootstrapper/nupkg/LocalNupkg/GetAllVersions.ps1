param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_nupkg_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name GetAllVersions `
        -Value {
            param( $Name )

            $combined = New-Object System.Collections.ArrayList
            
            $main = $this.PackageManagement.GetFromMain( $Name ).Version
            $cache = $this.PackageManagement.GetFromCache( $Name ).Version
            $patch = $this.PackageManagement.GetFromPatches( $Name ).Version

            If( $main.Count -eq 1 ){
                $combined.Add( $main )
            } Elseif( $main.Count ) {
                $combined.AddRange( $main )
            }
            If( $cache.Count -eq 1 ){
                $combined.Add( $cache )
            } Elseif( $cache.Count ) {
                $combined.AddRange( $cache )
            }
            If( $patch.Count -eq 1 ){
                $combined.Add( $patch )
            } Elseif( $patch.Count ) {
                $combined.AddRange( $patch )
            }

            $combined = $combined | Sort-Object -Unique

            [Array]::Sort[string]( $combined, [System.Comparison[string]]({
                param($x, $y)
                $x = $Bootstrapper.SemVer.Parse( $x )
                $y = $Bootstrapper.SemVer.Parse( $y )

                $Bootstrapper.SemVer.Compare( $x, $y )
            }))

            $combined
        }
}