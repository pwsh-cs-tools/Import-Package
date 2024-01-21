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
                    Throw "Name cannot be null or whitespace"
                } Else {
                    If( $Name.Version -eq $null ) {
                        $Version = $this.GetStable( $Name.Name )
                    } Else {
                        $Version = $Name.Version
                    }
                    $Name
                }
            } ElseIf( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "Name cannot be null or whitespace"
            } Else {
                If( $Version -eq $null ) {
                    $Version = $this.GetStable( $Name )
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