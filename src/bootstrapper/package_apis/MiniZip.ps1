param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $minizip = New-Object psobject
    $minizip | Add-Member `
        -MemberType NoteProperty `
        -Name RemoteZipReaderFactory `
        -Value (& {
            $client = [System.Net.Http.HttpClient]::new()
            [Knapcode.MiniZip.HttpZipProvider]::new($client)
        })

    $minizip | Add-Member `
        -MemberType ScriptMethod `
        -Name GetRemoteZipEntries `
        -Value {
            param(
                [string] $Url
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "Name cannot be null or whitespace"
            }

            $reader = $this.RemoteZipReaderFactory.GetReaderAsync( $Url )
            $reader = $reader.GetAwaiter().GetResult()

            $dir_records = $reader.ReadAsync().GetAwaiter().GetResult()
            $dir_records.Entries | ForEach-Object {
                [Knapcode.MiniZip.ZipEntryExtensions]::GetName($_)
            }
        }
    
    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name MiniZip `
        -Value $minizip
}