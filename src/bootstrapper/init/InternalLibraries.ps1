param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    <#
        Identifies libraries required by Import-Package.
        - If the library is loaded, it returns the most significant exposed type
        - If the library isn't loaded, it returns 0.
    #>
    $Bootstrapper | Add-Member `
        -MemberType ScriptProperty `
        -Name InternalLibraries `
        -Value {
            [ordered]@{
                "Nuget.Frameworks" = (& {
                    Try{ [NuGet.Frameworks.FrameworkConstants+FrameworkIdentifiers] } Catch { [int]0 }
                })
                "Knapcode.MiniZip" = (& {
                    Try{ [Knapcode.MiniZip.HttpZipProvider] } Catch { [int]0 }
                })
            }
        }
        # -SecondValue $null
}