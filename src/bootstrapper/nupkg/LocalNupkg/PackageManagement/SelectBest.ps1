param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_package_manager,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_package_manager | Add-Member `
        -MemberType ScriptMethod `
        -Name SelectBest `
        -Value {
            param(
                [string] $Name,
                [string] $Version
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(PackageManagement.SelectBest)] Name cannot be null or whitespace"
            }

            $main = $this.GetFromMain( $Name, $Version )
            $cache = $this.GetFromCache( $Name, $Version )
            $patch = $this.GetFromPatches( $Name, $Version )

            If( [string]::IsNullOrWhiteSpace( $Version ) ){
                $combined = New-Object System.Collections.ArrayList
                If( $main.Count -eq 1 ){
                    $combined.Add( $main.Version )
                } Elseif( $main.Count ) {
                    $combined.AddRange( $main.Version )
                }
                If( $cache.Count -eq 1 ){
                    $combined.Add( $cache.Version )
                } Elseif( $cache.Count ) {
                    $combined.AddRange( $cache.Version )
                }
                If( $patch.Count -eq 1 ){
                    $combined.Add( $patch.Version )
                } Elseif( $patch.Count ) {
                    $combined.AddRange( $patch.Version )
                }

                [Array]::Sort[string]( $combined, [System.Comparison[string]]({
                    param($x, $y)
                    $x = $Bootstrapper.SemVer.Parse( $x )
                    $y = $Bootstrapper.SemVer.Parse( $y )
    
                    $Bootstrapper.SemVer.Compare( $x, $y )
                }))

                $combined = $combined | Sort-Object -Unique
                
                $Version = $combined | Where-Object {
                    $parsed = $Bootstrapper.Semver.Parse( $_ )
    
                    -not( $parsed.PreRelease <# -or $parsed.LegacyPrerelease #> )
                } | Select-Object -Last 1
            }

            $package = @(
                ($main | Where-Object { $_.Version -eq $Version }), 
                ($cache | Where-Object { $_.Version -eq $Version }),
                ($patch | Where-Object { $_.Version -eq $Version })
            ) | Where-Object { $_ } | Select-Object -First 1

            $package
        }
}