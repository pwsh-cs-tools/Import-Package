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
        -Name ListEntries `
        -Value {
            param(
                $Name,
                [string] $Version
            )

            $package = If( $Name.GetType() -ne [string] ){
                If( [string]::IsNullOrWhiteSpace( $Name.Name ) ){
                    Throw "[Import-Package:Internals(LocalNupkg.ListEntries)] Name cannot be null or whitespace"
                } Else {
                    $Name
                }
            } ElseIf( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(LocalNupkg.ListEntries)] Name cannot be null or whitespace"
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

            $nupkg.Entries | ForEach-Object {
                $_.FullName
            }

            $nupkg.Dispose()
        }
}