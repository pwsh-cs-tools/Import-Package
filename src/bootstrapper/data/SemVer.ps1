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

            param( [string] $semVerString )

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

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name SemVer `
        -Value $semantic_versioning_reader
}