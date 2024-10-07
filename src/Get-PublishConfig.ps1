[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_ | Test-Path -PathType Container })]
    [string]
    $RootPath, 

    [Parameter(Mandatory)]
    [string]
    $ModuleName
)

#* Defaults
$jsonDepth = 2

$configPath_module = Join-Path $RootPath $ModuleName "publishconfig.json"
$configPath_root = Join-Path $RootPath "publishconfig.json"

#* Get config
if (Test-Path $configPath_module) {
    $configContent = Get-Content $configPath_module
    Write-Debug "[Get-PublishConfig()] Found publishconfig.json file: $configPath_module"
}
elseif (Test-Path $configPath_root) {
    $configContent = Get-Content $configPath_root
    Write-Debug "[Get-PublishConfig()] Found publishconfig.json file: $configPath_root"
}
else {
    throw [System.IO.FileNotFoundException]"Cannot find 'publishconfig.json' configuration file. This file is required."
}

$config = $configContent | ConvertFrom-Json -Depth $jsonDepth -AsHashtable -NoEnumerate
Write-Debug "[Get-PublishConfig()] Found publishconfig: $($config | ConvertTo-Json -Depth $jsonDepth))"

#* Return config object
$config