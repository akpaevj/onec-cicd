Param (
    [string]$Server,
    [string]$InfobaseName,
    [string]$InfobaseUser,
    [string]$InfobasePassword,
    [string]$Version = "8\.3\..*",
    [string]$Arch = "x86" # x86 or x64
)

if ($Arch -eq "x86") {
    $parentCatalog = "C:\Program Files (x86)\1cv8"
}
else {
    $parentCatalog = "C:\Program Files\1cv8"
}

$platforms = Get-ChildItem $parentCatalog | Where-Object { $_.Name -match $Version } | Sort-Object { $_.Name } -Descending

if ($platforms.Length -eq 0) {
    throw "Couldn't get path to the rac.exe"
}
else {
    $path = $platforms[0].FullName + "\bin\1cv8.exe"
}

if ($path -eq [string]::Empty -or !(Test-Path $path)) {
    throw "Couldn't find 1cv8.exe file by path $path"
} else {
    cmd /c """$path"" DESIGNER /S$Server\$InfobaseName /U""$InfobaseUser"" /P$InfobasePassword /AgentMode /AgentSSHHostKeyAuto"
}