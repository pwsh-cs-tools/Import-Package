param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $nuget = New-Object psobject
    $nuget | Add-Member `
        -MemberType NoteProperty `
        -Name Reducer `
        -Value ([NuGet.Frameworks.FrameworkReducer]::new())

    $nuget | Add-Member `
        -MemberType NoteProperty `
        -Name Frameworks `
        -Value @{}
    
    [NuGet.Frameworks.FrameworkConstants+FrameworkIdentifiers].DeclaredFields | ForEach-Object {
        $nuget.Frameworks[$_.Name] = $_.GetValue( $null )
    }

    $Bootstrapper | Add-Member `
        -MemberType ScriptProperty `
        -Name Nuget `
        -Value $nuget
}