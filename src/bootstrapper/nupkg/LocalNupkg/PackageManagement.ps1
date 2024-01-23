param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_nupkg_reader,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_nupkg_reader | Add-Member `
        -MemberType NoteProperty `
        -Name PackageManagement `
        -Value (& {
            $sources = New-Object psobject

            $sources | Add-Member `
                -MemberType NoteProperty `
                -Name Directories `
                -Value (& {
                    $directories = @{}

                    # see: https://github.com/OneGet/oneget/blob/WIP/src/Microsoft.PackageManagement/Implementation/PackageManagementService.cs#L149-L195
                    $basepaths = @{}

                    If( [Environment]::SpecialFolder ){
                        $basepaths.User = [Environment]::GetFolderPath( [Environment+SpecialFolder]::LocalApplicationData )
                        $basepaths.System = [Environment]::GetFolderPath( [Environment+SpecialFolder]::ProgramFiles )
                    } Else {
                        $basepaths.User = [Environment]::GetFolderPath( "LocalApplicationData" )
                        $basepaths.System = [Environment]::GetFolderPath( "ProgramFiles" )
                    }

                    $directories.User = Join-Path $basepaths.User "PackageManagement\NuGet\Packages"
                    $directories.System = Join-Path $basepaths.System "PackageManagement\NuGet\Packages"
                    
                    $directories.Fallback = Join-Path $Bootstrapper.Root "Packages"
                    $directories.Patches = Join-Path $Bootstrapper.Root "Patches"

                    $directories
                })

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromMain `
                -Value {
                    param(
                        [string] $Name
                    )

                    If( [string]::IsNullOrWhiteSpace( $Name ) ){
                        Throw "Name cannot be null or whitespace"
                    }

                    $cache_paths = @(
                        $this.Directories.User,
                        $this.Directories.System
                    )

                    $this.GetFromCache( $Name, $cache_paths )

                    # Get-Package $Name -AllVersions -ProviderName NuGet -ErrorAction SilentlyContinue
                }

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromCache `
                -Value {
                    param(
                        [string] $Name,
                        $CachePath = $this.Directories.Fallback
                    )

                    If( [string]::IsNullOrWhiteSpace( $Name ) ){
                        Throw "Name cannot be null or whitespace"
                    }

                    # Get all cached packages with the same name
                    $cache_files = $CachePath | ForEach-Object {
                        Try {
                            Join-Path $_ "*" | Resolve-Path
                        } Catch { $null }
                    }
                    $candidate_packages = Try {
                        $cache_files | Split-Path -Leaf | Where-Object {
                            $leaf = $_.ToLower()
                            $check = $Name.ToLower()
                            $ending_tokens = "$leaf".Replace( $check, "" ) -replace "^\.",""
                            $first_token = ($ending_tokens -split "\.")[0]
                            Try{
                                $null = [int]$first_token
                                $true
                            } Catch {
                                $false
                            }
                        }
                    } Catch { $null }
    
                    If( $candidate_packages ){
    
                        # Get all versions in the directory
                        $candidate_versions = $candidate_packages | ForEach-Object {
                            $leaf = $_.ToLower()
                            $check = $Name.ToLower()
                            # Exact replace (.Replace()) followed by regex-replace (-replace)
                            "$leaf".Replace( $check, "" ) -replace "^\.",""
                        }
        
                        $candidate_versions = [string[]] $candidate_versions
    
                        [Array]::Sort[string]( $candidate_versions, [System.Comparison[string]]({
                            param($x, $y)
                            $x = $Bootstrapper.SemVer.Parse( $x )
                            $y = $Bootstrapper.SemVer.Parse( $y )
        
                            $Bootstrapper.SemVer.Compare( $x, $y )
                        }))

                        $candidate_versions | ForEach-Object {
                            $iter_version = $_
                            $candidates = $CachePath | ForEach-Object { Join-Path $_ "$Name.$iter_version" "$Name.$iter_version.nupkg" }
                            $candidates | ForEach-Object {
                                $candidate = $_
                                If( Test-Path $candidate ){
                                    New-Object psobject -Property @{
                                        Name = $Name
                                        Version = $iter_version
                                        Source = $candidate
                                    }
                                }
                            }
                        }
                    }
                }

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromPatches `
                -Value {
                    param(
                        [string] $Name,
                        $PatchPath = $this.Directories.Patches
                    )

                    If( [string]::IsNullOrWhiteSpace( $Name ) ){
                        Throw "Name cannot be null or whitespace"
                    }

                    $this.GetFromCache( $Name, $PatchPath )
                }

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name SelectBest `
                -Value {
                    param(
                        [string] $Name,
                        [string] $Version
                    )

                    If( [string]::IsNullOrWhiteSpace( $Name ) ){
                        Throw "Name cannot be null or whitespace"
                    }

                    $main = $this.GetFromMain( $Name )
                    $cache = $this.GetFromCache( $Name )
                    $patch = $this.GetFromPatches( $Name )

                    If( [string]::IsNullOrWhiteSpace( $Version ) ){
                        $combined = New-Object System.Collections.ArrayList
                        If( $main.Count -eq 1 ){
                            $combined.Add( $main.Version )
                        } Elseif( $main.Count ) {
                            $combined.AddRange( $main.Version )
                        }
                        If( $cache.Count -eq 1 ){
                            $combined.Add( $cache.Version )
                        } Elseif( $cache.Count ) {
                            $combined.AddRange( $cache.Version )
                        }
                        If( $patch.Count -eq 1 ){
                            $combined.Add( $patch.Version )
                        } Elseif( $patch.Count ) {
                            $combined.AddRange( $patch.Version )
                        }

                        [Array]::Sort[string]( $combined, [System.Comparison[string]]({
                            param($x, $y)
                            $x = $Bootstrapper.SemVer.Parse( $x )
                            $y = $Bootstrapper.SemVer.Parse( $y )
            
                            $Bootstrapper.SemVer.Compare( $x, $y )
                        }))

                        $combined = $combined | Sort-Object -Unique
                        
                        $Version = $combined | Where-Object {
                            $parsed = $Bootstrapper.Semver.Parse( $_ )
            
                            -not( $parsed.PreRelease <# -or $parsed.LegacyPrerelease #> )
                        } | Select-Object -Last 1
                    }

                    $package = @(
                        ($main | Where-Object { $_.Version -eq $Version }), 
                        ($cache | Where-Object { $_.Version -eq $Version }),
                        ($patch | Where-Object { $_.Version -eq $Version })
                    ) | Where-Object { $_ } | Select-Object -First 1

                    $package
                }

            $sources
        })
}