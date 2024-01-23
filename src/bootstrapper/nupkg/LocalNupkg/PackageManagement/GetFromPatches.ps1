param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_package_manager
)

& {
    $local_package_manager | Add-Member `
        -MemberType ScriptMethod `
        -Name GetFromPatches `
        -Value {
            param(
                [string] $Name,
                [string] $Version,
                $PatchPath = $this.Directories.Patches
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(PackageManagement.GetFromPatches)] Name cannot be null or whitespace"
            }

            $this.GetFromCache( $Name, $Version, $PatchPath )
        }
}