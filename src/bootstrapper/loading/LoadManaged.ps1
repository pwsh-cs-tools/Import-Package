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
                Throw "[Import-Package:Internals(LoadManaged)] Name cannot be null or whitespace"
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
                    Throw "[Import-Package:Internals(LoadManaged)] Unable to find $Path"
                }

                Add-Type @AddTypeParams
                
            } catch {
                Throw "[Import-Package:Internals(LoadManaged)] Unable to load $Path`n$($_.Exception.Message)"
            }
        }
}