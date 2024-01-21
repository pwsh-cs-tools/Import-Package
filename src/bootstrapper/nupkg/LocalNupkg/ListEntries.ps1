param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_nupkg_reader
)

& {
    $local_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ListEntries `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Path
            )
            $nupkg = [System.IO.Compression.ZipFile]::OpenRead( $path )

            $nupkg.Entries | ForEach-Object {
                $_.FullName
            }

            $nupkg.Dispose()
        }
}