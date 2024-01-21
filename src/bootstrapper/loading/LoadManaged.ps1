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

            If( [string]::IsNullOrWhiteSpace( $Path ) ){
                Throw "Name cannot be null or whitespace"
            }

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
                
            } catch {
                Write-Error "[Import-Package:Internals] Unable to load $Path`n$($_.Exception.Message)"
            }
        }
}