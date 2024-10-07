[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ $_ | Test-Path -PathType Container })]
    [string]
    $RootPath,

    [Parameter(Mandatory)]
    [string]
    $ModuleName,
    
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [string[]]
    $ExistingTags,
    
    [Parameter(Mandatory)]
    [bool]
    $UpdateParentVersions,
    
    [Parameter(Mandatory)]
    [bool]
    $Force
)

Write-Debug "Get-VersionsToUpdate.ps1: Started"
Write-Debug "Input parameters: $($PSBoundParameters | ConvertTo-Json -Depth 3)"

$modulePath = Join-Path -Path $RootPath -ChildPath $ModuleName
$versionPath = Join-Path $modulePath -ChildPath "version.json"

#* Test version
$versionString = (Get-Content -Path $versionPath -ErrorAction Stop | ConvertFrom-Json -Depth 1 -AsHashtable).version

$version = [semver]$versionString

$versionsToUpdate = @()

$versionTag = "$ModuleName/$($version.ToString())"
if ($ExistingTags -contains $versionTag) {
    if ($Force) {
        Write-Warning "Version tag '$versionTag' already exists. Force parameter set to 'true'. Overwriting tags and modules."
        $versionsToUpdate += $version.ToString()
    }
    else {
        throw "Version tag '$versionTag' already exists. Force parameter set to 'false'. Not updating any tags or modules"
    }
}
else {
    Write-Host "Version tag '$versionTag' does not exist. Writing tags and modules."
    $versionsToUpdate += $version.ToString()
}

if ($UpdateParentVersions) {
    if ($version.PreReleaseLabel -or $version.BuildLabel) {
        Write-Warning "Version includes PreReleaseLabel or BuildLabel. Treating it as a non-stable release. Not updating parent versions."
    }
    elseif ($versionsToUpdate -notcontains $version.ToString()) {
        Write-Host "Parent versions not updated as base version is not updated."
    }
    else {
        $versionsToUpdate += "$($version.Major).$($version.Minor)"
        $versionsToUpdate += "$($version.Major)"
    }
}

return , $versionsToUpdate
