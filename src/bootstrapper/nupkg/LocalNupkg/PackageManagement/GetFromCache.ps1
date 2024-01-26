param(
    [parameter(Mandatory = $true)]
    [psobject]
    $local_package_manager,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $local_package_manager | Add-Member `
        -MemberType ScriptMethod `
        -Name GetFromCache `
        -Value {
            param(
                [string] $Name,
                [string] $Version,
                $CachePath = $this.Directories.Cache
            )

            If( [string]::IsNullOrWhiteSpace( $Name ) ){
                Throw "[Import-Package:Internals(PackageManagement.GetFromCache)] Name cannot be null or whitespace"
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

                $candidate_versions = $Bootstrapper.SemVer.Sort( $candidate_versions )

                $candidate_versions = If( [string]::IsNullOrWhiteSpace( $Version ) ){
                    $candidate_versions
                } Else {
                    $candidate_versions | Where-Object {
                        $Bootstrapper.SemVer.Compare( $Bootstrapper.SemVer.Parse( $_ ), $Bootstrapper.SemVer.Parse( $Version ) ) -eq 0
                    }
                }

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
}