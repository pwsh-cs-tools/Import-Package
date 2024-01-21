param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_nupkg_reader = New-Object psobject
    
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

    $local_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ReadNuspec `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Path
            )
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
                    Write-Warning "Improper .nuspec used for $nupkg_name`: $( $nuspec.FullName )"
                } Else {
                    Throw ".nuspec file not found for $nupkg_name`!"
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

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name LocalNupkg `
        -Value $local_nupkg_reader
}