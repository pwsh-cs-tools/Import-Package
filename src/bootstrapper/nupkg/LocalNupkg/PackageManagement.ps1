param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_nupkg_reader
)

& {
    $local_nupkg_reader | Add-Member `
        -MemberType NoteProperty `
        -Name PackageManagement `
        -Value (& {
            $sources = New-Object psobject

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromMain `
                -Value {
                    param( $Name )
                    Get-Package $Name
                }

            <#

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromCache `
                -Value {
                    param( $Name )
                    
                }

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromPatches `
                -Value {
                    param( $Name )
                    
                }

            #>

            $sources
        })
}