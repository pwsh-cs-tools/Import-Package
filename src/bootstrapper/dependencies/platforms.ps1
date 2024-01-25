param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name GetPlatformFolders `
        -Value {
            param(
                [string] $Name,
                [string] $Version,
                [bool] $Upstream = $true
            )

            $Version = If( $Upstream ){
                $stable_version = $this.RemoteNupkg.GetStable( $Name, $Version )
                If( [string]::IsNullOrWhiteSpace( $stable_version ) ){
                    $this.RemoteNupkg.GetPreRelease( $Name, $Version )
                } Else {
                    $stable_version
                }
            }

            $entries = If( $Upstream ){
                $this.RemoteNupkg.ListEntries( $Name, $Version )
            } Else {
                $this.LocalNupkg.ListEntries( $Name, $Version )
            }

            $dlls = @{}
            $dlls.AnyFramework = $entries | Where-Object {
                $_ -match "lib[\/\\][^\/\\]*\.dll"
            }
            $dlls.FrameworkSpecific = $entries | Where-Object {
                $_ -match "lib[\/\\][^\/\\]*[\/\\][^\/\\]*\.dll"
            }
            $dlls.RuntimeSpecific = @{}
            
            $runtimes = $entries | Where-Object {
                $_ -match "runtimes[\/\\][^\/\\]*[\/\\].*\.(?:dll|so|dylib)"
            } | ForEach-Object {
                $_ -match "runtimes[\/\\]([^\/\\]*)[\/\\].*\.(?:dll|so|dylib)" | Out-Null
                $matches[1]
            } | Sort-Object -Unique

            $runtimes | ForEach-Object {
                $runtime = $_
                $dlls.RuntimeSpecific."$runtime" = @{}
                $dlls.RuntimeSpecific."$runtime".AnyFramework = $entries | Where-Object {
                    $_ -match "runtimes[\/\\]$runtime[\/\\]lib[\/\\][^\/\\]*\.dll"
                }
                $dlls.RuntimeSpecific."$runtime".FrameworkSpecific = $entries | Where-Object {
                    $_ -match "runtimes[\/\\]$runtime[\/\\]lib[\/\\][^\/\\]*[\/\\][^\/\\]*\.dll"
                }
                $dlls.RuntimeSpecific."$runtime".Native = $entries | Where-Object {
                    $_ -match "runtimes[\/\\]$runtime[\/\\]native[\/\\][^\/\\]*\.(?:dll|so|dylib)"
                }
            }

            
            [System.Collections.Generic.Dictionary[string,System.Object]] $platform_folders = [System.Collections.Generic.Dictionary[string,System.Object]]::new()

            $platform_folders.FrameworkFiles = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]]::new()
            $platform_folders.RuntimeFiles = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]]]::new()

            If( $dlls.AnyFramework.Count ){
                $platform_folders.FrameworkFolders.Any = [System.Collections.Generic.List[string]]::new()
                $dlls.AnyFramework | ForEach-Object {
                    $platform_folders.FrameworkFolders.Any.Add( $_ )
                }
            }

            $dlls.FrameworkSpecific | Group-Object -Property {
                $_ -match "lib[\/\\]([^\/\\]*)[\/\\][^\/\\]*\.dll"
                $matches[1]
            } | ForEach-Object {
                $framework = $_.Name
                $platform_folders.FrameworkFiles."$framework" = [System.Collections.Generic.List[string]]::new()
                $_.Group | ForEach-Object {
                    $platform_folders.FrameworkFiles."$framework".Add( $_ )
                }
            }

            $dlls.RuntimeSpecific.GetEnumerator() | ForEach-Object {
                $runtime = $_.Key
                $platform_folders.RuntimeFiles."$runtime" = [System.Collections.Generic.Dictionary[string,System.Collections.Generic.List[string]]]::new()
                If( $_.Value.AnyFramework.Count ){
                    $platform_folders.RuntimeFiles."$runtime".FrameworkFolders.Any = [System.Collections.Generic.List[string]]::new()
                    $_.Value.AnyFramework | ForEach-Object {
                        $platform_folders.RuntimeFiles."$runtime".FrameworkFolders.Any.Add( $_ )
                    }
                }
                $_.Value.FrameworkSpecific | Group-Object -Property {
                    $_ -match "lib[\/\\]([^\/\\]*)[\/\\][^\/\\]*\.dll"
                    $matches[1]
                } | ForEach-Object {
                    $framework = $_.Name
                    $platform_folders.RuntimeFiles."$runtime".FrameworkFiles."$framework" = [System.Collections.Generic.List[string]]::new()
                    $_.Group | ForEach-Object {
                        $platform_folders.RuntimeFiles."$runtime".FrameworkFiles."$framework".Add( $_ )
                    }
                }
                If( $_.Value.Native.Count ){
                    $platform_folders.RuntimeFiles."$runtime".Native = [System.Collections.Generic.List[string]]::new()
                    $_.Value.Native | ForEach-Object {
                        $platform_folders.RuntimeFiles."$runtime".Native.Add( $_ )
                    }
                }
            }

            $platform_folders
        }
}