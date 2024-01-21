param(
    [parameter(Mandatory = $true)]
    [psobject]
    $remote_nupkg_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $remote_nupkg_reader | Add-Member `
        -MemberType ScriptMethod `
        -Name ListEntries `
        -Value {
            param(
                [parameter(Mandatory = $true)]
                [string]
                $Name,
                [string] $Verion
            )

            $url = $this.GetDownloadUrl( $Name, $Version )

            $Bootstrapper.MiniZip.GetRemoteZipEntries( $url )
        }
}