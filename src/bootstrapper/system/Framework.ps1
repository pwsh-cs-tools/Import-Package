param(
    [parameter(Mandatory = $true)]
    [psobject]
    $system_identifiers,
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $system_identifiers | Add-Member `
        -MemberType NoteProperty `
        -Name Framework `
        -Value (& {
            $runtime = [System.Runtime.InteropServices.RuntimeInformation, mscorlib]::FrameworkDescription
            $version = $runtime -split " " | Select-Object -Last 1
            $framework_name = ($runtime -split " " | Select-Object -SkipLast 1) -join " "
        
            If( $framework_name -eq ".NET Framework" ) {
                $framework_name = "Net"
            } else {
                $framework_name = "NETCoreApp"
            }
        
            "$( $Bootstrapper.Nuget.Frameworks[ $framework_name ] ),Version=v$version" -as [NuGet.Frameworks.NuGetFramework]
        })
}