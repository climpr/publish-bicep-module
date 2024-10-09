[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_ | Test-Path -PathType Container })]
    [string]
    $Path
)

if (!(Test-Path "$Path/main.bicep")) {
    throw [System.IO.FileNotFoundException]"'main.bicep' does not exist. This file is required."
}

if (!(Test-Path "$Path/version.json")) {
    throw [System.IO.FileNotFoundException]"'version.json' does not exist. This file is required."
}

if (!(Test-Path "$Path/README.md")) {
    throw [System.IO.FileNotFoundException]"'README.md' does not exist. This file is required."
}