$global:__testing = $true
$VerbosePreference = "Continue"

Import-Module "PackageManagement"

Write-Host "[Import-Package:Testing] Begin Testing?"
pause;

Measure-Command {
    Import-Module "$Root\Import-Package\"
}

Write-Host "[Import-Package:Testing] Initialized. Continue Testing?"
pause;

# --- Basic Testing ---

Measure-Command {
    Write-Host "[Import-Package:Testing] Testing with Avalonia.Desktop and Microsoft.ClearScript"

    Import-Package Avalonia.Desktop -Offline
    Import-Package Microsoft.ClearScript -Offline
}

Write-Host "[Import-Package:Testing] Avalonia.Desktop and Microsoft.ClearScript should be loaded. Continue Testing?"
pause;

# --- Path Parameter Testing ---

Write-Host "[Import-Package:Testing] Testing the Unmanaged Parameterset"

$unmanaged = @{}

# Has no dependencies
$unmanaged.Simple = Get-Package NewtonSoft.json

# Has 1 dependency
$unmanaged.Complex = Get-Package NLua

$unmanaged.Simple = $unmanaged.Simple.Source
$unmanaged.Complex = $unmanaged.Complex.Source

Measure-Command { Import-Package -Path $unmanaged.Simple }
Write-Host "[Import-Package:Testing] Testing the Unmanaged Parameterset with a simplistic package is complete. Continue Testing?"
pause;

Measure-Command { Import-Package -Path $unmanaged.Complex }
Write-Host "[Import-Package:Testing] Testing the Unmanaged Parameterset with a complex package is complete. Continue Testing?"
pause;

Measure-Command { Import-Package NLua -SkipDependencies }
Write-Host "[Import-Package:Testing] Testing the -SkipDependencies switch is complete. Continue Testing?"
pause;

Measure-Command { Import-Package IronRuby.Libraries }
Write-Host "[Import-Package:Testing] Testing the Semver2 packages (and the package cache) is complete. Continue Testing?"
pause;

@(
    [Microsoft.ClearScript.V8.V8ScriptEngine]
    [Avalonia.Application]
    [Newtonsoft.Json.JsonConverter]
    [NLua.Lua]
    [IronRuby.Ruby]
) | Format-Table

Write-Host
Write-Host "System Runtime ID:" (Get-Runtime)