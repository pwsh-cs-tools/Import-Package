param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_package_manager
)

& {
    $local_package_manager | Add-Member `
        -MemberType ScriptMethod `
        -Name GetFromMain `
        -Value {
            param(
                [string] $Name
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(PackageManagement.GetFromMain)] Name cannot be null or whitespace"
            }

            $cache_paths = @(
                $this.Directories.User,
                $this.Directories.System
            )

            $this.GetFromCache( $Name, $cache_paths )

            # Get-Package $Name -AllVersions -ProviderName NuGet -ErrorAction SilentlyContinue
        }
}