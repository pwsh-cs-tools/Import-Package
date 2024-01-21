param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    <#
        Identifies libraries required by Import-Package.
        - If the library is loaded,
          - and exports types, it returns the most significant type
          - and doesn't export anything, it returns 1
        - If the library isn't loaded, it returns 0.
    #>
    #   If it exports no types, it returns 1
    $Bootstrapper | Add-Member `
        -MemberType ScriptProperty `
        -Name InternalLibraries `
        -Value {
            @{
                "Nuget.Frameworks" = (& {
                    Try{ [NuGet.Frameworks.FrameworkConstants+FrameworkIdentifiers] } Catch { [int]0 }
                })
                "Knapcode.MiniZip" = (& {
                    Try{ [Knapcode.MiniZip.HttpZipProvider] } Catch { [int]0 }
                })
                "Microsoft.NETCore.Platforms"  = (& {
                    # Doesn't export anything. Provides a JSON file for identifying RIDs
                    If( Get-Package "Microsoft.NETCore.Platforms" -ProviderName NuGet -ErrorAction SilentlyContinue ){
                        [int]1
                    } Else {
                        [int]0
                    }
                })
            }
        }
        # -SecondValue $null
}