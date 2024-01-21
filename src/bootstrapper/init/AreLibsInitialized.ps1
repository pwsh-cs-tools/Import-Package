param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $Bootstrapper | Add-Member `
        -MemberType ScriptMethod `
        -Name AreLibsInitialized `
        -Value {
            $libs = $this.InternalLibraries
            (@(
                "Nuget.Frameworks",
                "Knapcode.Minizip"
            ) | Where-Object { $libs."$_" -eq ([int]0) }).Count -eq 0
        }
}