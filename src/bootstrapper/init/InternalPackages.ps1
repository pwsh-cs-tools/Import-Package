param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $internal_libraries = [System.Collections.ArrayList]::new()
    $internal_libraries.AddRange( $Bootstrapper.InternalLibraries.Keys )
    
    $internal_packages = @{}

    # The following iterates through InternalLibraries and gets the packages for them and any dependencies
    $package_name = ""; $i = 0;
    while( $i -lt $internal_libraries.Count ){
        $package_name = $internal_libraries[ $i ]
        If( -not( $internal_packages.ContainsKey( $package_name ) ) ){
            $package = $Bootstrapper.Ensure( $package_name )

            $internal_packages[ $package_name ] = $package

            $package_nuspec = $Bootstrapper.LocalNupkg.ReadNuspec( $package )
            $dependencies = If( $package_nuspec.package.metadata.dependencies.group ){
                $package_nuspec.package.metadata.dependencies.group
            } Else {
                $package_nuspec.package.metadata.dependencies
            }

            $netstandard_dependencies = $dependencies | Where-Object { $_.targetframework -eq "netstandard2.0" }
            $netstandard_dependencies = $netstandard_dependencies.dependency | Where-Object { $_.id }

            foreach( $dependency in $netstandard_dependencies ){
                $internal_libraries.Add( $dependency.id ) | Out-Null
            }
        } else {
            $oldindex = $internal_libraries.IndexOf( $package_name )
            $internal_libraries.RemoveAt( $oldindex ) | Out-Null
            $internal_libraries.Add( $package_name ) | Out-Null
        }

        $i += 1
    }

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name InternalPackages `
        -Value $internal_packages

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name InternalPackagesOrder `
        -Value $internal_libraries
}