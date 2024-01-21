param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name LoadManaged `
        -Value {
            param(
                [string] $Path,
                [bool] $Partial = $false
            )

            # todo: add handling of native/unmanaged assemblies

            try {

                $AddTypeParams = @{
                    # PassThru = $false
                }
    
                if( $Partial ) {
                    $AddTypeParams.AssemblyName = $Path
                } elseif ( Test-Path $Path ) {
                    $AddTypeParams.Path = $Path
                } else {
                    Write-Host "Unable to load $Path"
                    return
                }

                Add-Type @AddTypeParams
                
            } catch { Write-Host "Unable to load $Path" }
        }
}