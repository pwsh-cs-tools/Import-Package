param(
    [parameter(Mandatory = $true)]
    [psobject]
    $Bootstrapper
)

& {
    $classes = @(
        "PackageData",
        "DependencyData",
        "Globals"
    )

    $source_code = New-Object System.Collections.ArrayList
    $source_code.Add( @"
using System;
"@) | Out-Null

    $classes | ForEach-Object {
        $classname = $_

        $main = Resolve-Path "$PSScriptRoot\$classname\$classname.cs" -ErrorAction Stop | ForEach-Object {
            Get-Content -Path $_.Path -Raw
        }
    
        $source_code.Add( $main ) | Out-Null
    
        $components = Resolve-Path "$PSScriptRoot\$classname\$classname.*.cs" -ErrorAction SilentlyContinue | ForEach-Object {
            Get-Content -Path $_.Path -Raw
        }
    
        If( $components.Count ){
            $source_code.AddRange( $components ) | Out-Null
        }
    }
    Try {
        Add-Type `
            -TypeDefinition ( $source_code -join "`n" ) | Out-Null
    } Catch {
        throw [System.Exception]::new( "[Import-Package:Internals] Could not load csharp definitions", $_.Exception )
    }

    [ImportPackage.Globals]::Instance.Bootstrapper = $Bootstrapper

    $Bootstrapper | Add-Member `
        -MemberType NoteProperty `
        -Name Types `
        -Value @{
            PackageData = [ImportPackage.PackageData]
            DependencyData = [ImportPackage.DependencyData]
        }
}