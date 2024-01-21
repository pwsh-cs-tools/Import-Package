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
                -MemberType ScriptMethod `
                -Name GetFromMain `
                -Value {
                    param(
                        [string] $Name
                    )

                    If( [string]::IsNullOrWhiteSpace( $Name ) ){
                        Throw "Name cannot be null or whitespace"
                    }

                    # see: https://github.com/OneGet/oneget/blob/WIP/src/Microsoft.PackageManagement/Implementation/PackageManagementService.cs#L149-L195
                    $basepaths = @{}

                    If( [Environment]::SpecialFolder ){
                        $basepaths.User = [Environment]::GetFolderPath( [Environment+SpecialFolder]::LocalApplicationData )
                        $basepaths.System = [Environment]::GetFolderPath( [Environment+SpecialFolder]::ProgramFiles )
                    } Else {
                        $basepaths.User = [Environment]::GetFolderPath( "LocalApplicationData" )
                        $basepaths.System = [Environment]::GetFolderPath( "ProgramFiles" )
                    }

                    $cache_paths = @(
                        Join-Path $basepaths.User "PackageManagement\NuGet\Packages"
                        Join-Path $basepaths.System "PackageManagement\NuGet\Packages"
                    )

                    $this.GetFromCache( $Name, $cache_paths )

                    # Get-Package $Name -AllVersions -ProviderName NuGet -ErrorAction SilentlyContinue
                }

            $sources | Add-Member `
                -MemberType ScriptMethod `
                -Name GetFromCache `
                -Value {
                    param(
                        $Name,
                        $CachePath = (Join-Path $Bootstrapper.Root "Packages")
                    )

                    # Get all cached packages with the same name
                    $candidate_packages = Try {
                        Join-Path $CachePath "*" | Resolve-Path | Split-Path -Leaf | Where-Object {
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
                            $candidate = Join-Path $CachePath "$Name.$_" "$Name.$_.nupkg"
                            If( Test-Path $candidate ){
                                New-Object psobject -Property @{
                                    Name = $Name
                                    Version = $_
                                    Source = $candidate
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
                        $Name,
                        $PatchPath = (Join-Path $Bootstrapper.Root "Patches")
                    )

                    $this.GetFromCache( $Name, $PatchPath )
                }

            $sources
        })
}