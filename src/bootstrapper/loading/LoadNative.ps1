param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    # Native/Unmanaged assemblies
    Try {
        $Bootstrapper | Add-Member `
            -MemberType ScriptMethod `
            -Name LoadNative `
            -Value (& {
                Add-Type -MemberDefinition @"
[DllImport("kernel32")]
public static extern IntPtr LoadLibrary(string path);
[DllImport("libdl")]
public static extern IntPtr dlopen(string path, int flags);
"@ -Namespace "_Native" -Name "Loaders"
                
                {
                    param( $Path, $CopyTo )
                    If( $CopyTo ){
                        If( -not (Test-Path $CopyTo -PathType Container) ){
                            New-Item -ItemType Directory -Path $CopyTo -Force
                        }
                        Write-Verbose "[Import-Package:Internals(LoadNative)] Loading native dll from path '$CopyTo' (copying from '$Path')."
                        $end_path = "$CopyTo\$($Path | Split-Path -Leaf)"
                        If( Test-Path $end_path -PathType Leaf ){
                            Write-Verbose "[Import-Package:Internals(LoadNative)] $CopyTo is already present and loaded. Native dll not copied - This could cause version conflicts"
                        } Else {
                            Copy-Item $Path $CopyTo -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        $Path = $end_path
                    } Else {
                        Write-Verbose "[Import-Package:Internals(LoadNative)] Loading native dll from path '$Path'."
                    }
                    $lib_handle = [System.IntPtr]::Zero

                    If( [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows) ){
                        $lib_handle = [_Native.Loaders]::LoadLibrary( $Path )
                    } else {
                        $lib_handle = [_Native.Loaders]::dlopen( $Path, 0 )
                    }

                    If( $lib_handle -eq [System.IntPtr]::Zero ){
                        Throw "[Import-Package:Internals(LoadNative)] Unable to load $Path"
                    }

                    # BUG: Leaky handle
                    Write-Verbose "[Import-Package:Internals(LoadNative)] $Path returned leaky handle $lib_handle"
                }
            })
        
        $Bootstrapper | Add-Member `
            -MemberType ScriptMethod `
            -Name TestNative `
            -Value {
                param( $Path )
                try {
                    [Reflection.AssemblyName]::GetAssemblyName($Path) | Out-Null
                    return $false
                } catch {
                    return $true
                }
            }
            
    } Catch {}
}