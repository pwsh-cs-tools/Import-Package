param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name Init `
        -Value {
            $libs = $this.InternalLibraries
            $this.InternalPackagesOrder | ForEach-Object {
                $package = $this.InternalPackages[ "$_" ]
                $nupkg = $package.Source
                If( $libs[ $_ ] -eq [int]0 ){
                    $dll = Resolve-Path "$(Split-Path $nupkg -ErrorAction SilentlyContinue)\lib\netstandard2.0\$_.dll" -ErrorAction SilentlyContinue
                    $this.LoadManaged( $dll )
                }
            }
        }
}