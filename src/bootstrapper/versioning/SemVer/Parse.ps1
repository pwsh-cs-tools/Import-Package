param(
    [parameter(Mandatory = $true)]
    [psobject]
    $semantic_versioning_reader
)

& {

    $semantic_versioning_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name Parse `
        -Value {

            param(
                [string] $semVerString
            )
            
            If( [string]::IsNullOrWhiteSpace( $semVerString ) ){
                Throw "[Import-Package:Internals(SemVer.Parse)] Name cannot be null or whitespace"
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
                IsSemVer2 = ([string]::IsNullOrWhiteSpace( $preRelease ) -eq $false)
            }
            
        }

}