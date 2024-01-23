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
        -Name ReadNuspec `
        -Value {
            param(
                $Name,
                [string] $Version
            )

            $package = If( $Name.GetType() -ne [string] ){
                If( [string]::IsNullOrWhiteSpace( $Name.Name ) ){
                    Throw "[Import-Package:Internals(LocalNupkg.ReadNuspec)] Name cannot be null or whitespace"
                } Else {
                    $Name
                }
            } ElseIf( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(LocalNupkg.ReadNuspec)] Name cannot be null or whitespace"
            } Else {
                $Version = If( [string]::IsNullOrWhiteSpace( $Version ) ){
                    $latest_stable = $this.GetStable( $Name )
                    If( [string]::IsNullOrWhiteSpace( $latest_stable ) ){
                        $this.GetPreRelease( $Name )
                    } Else {
                        $latest_stable
                    }
                } Else {
                    $Version
                }

                $Bootstrapper.LocalNupkg.PackageManagement.SelectBest( $Name, $Version )
            }
            
            $path = $package.Source

            $nupkg = [System.IO.Compression.ZipFile]::OpenRead( $path )

            $nupkg_name = $Path | Split-Path -LeafBase

            $nuspecs = ($nupkg.Entries | Where-Object { $_.FullName -match "^[^\/\\]*.nuspec" })

            $nuspec = $nuspecs | Where-Object {
                $nuspec_name = $_.FullName | Split-Path -LeafBase
                $out = @(
                    ($nupkg_name -like "$nuspec_name.*"),
                    ($nupkg_name -like "$nuspec_name")
                )
                $out -contains $true
            }

            If ( -not( $nuspec ) ){
                $nuspec = $nuspecs | Select-Object -First 1
                If( $nuspec ){
                    Write-Warning "[Import-Package:Internals(LocalNupkg.ReadNuspec)] Improper .nuspec used for $nupkg_name`: $( $nuspec.FullName )"
                } Else {
                    Throw "[Import-Package:Internals(LocalNupkg.ReadNuspec)] .nuspec file not found for $nupkg_name`!"
                    return
                }
            }
            
            $stream = $nuspec.Open()
            $reader = New-Object System.IO.StreamReader( $stream )

            [xml]($reader.ReadToEnd())

            $reader.Close()
            $stream.Close()
            $nupkg.Dispose()
        }
}