param (
    [string]$commit = "",
    [string]$repository = "git@bitbucket.org:ltrace/slicer.git"
)

Write-Host "commit: $commit"
Write-Host "repository: $repository"


$repoFolder = Split-Path -Parent -Path $PSScriptRoot
$cmakelistsFilePath = Join-Path $repoFolder "CMakeLists.txt"

if ([string]::IsNullOrEmpty($commit)) {
    throw "The commit hash is missing"
}
 

if (-not (Test-Path $cmakelistsFilePath)) {
    throw "CMakeLists.txt not found at $repoFolder"
}

$data = Get-Content -Path $cmakelistsFilePath -Raw


if ([string]::IsNullOrEmpty($data)) {
    throw "The $cmakelistsFilePath is empty."
}

$regex = "(FetchContent_Populate(\s*|\S*)\((\s*|\S*)?slicersources(\s*|\S*)*\))"
$match = [regex]::Match($data, $regex)

if (-not $match.Success) {
    throw "Unable to find FetchContent_Populate related to the slicersources at $cmakelistsFilePath"
}

$new_data = $data.Substring(0, $match.Index) +
            @"
FetchContent_Populate(slicersources
    GIT_REPOSITORY $repository
    GIT_TAG $commit
    GIT_PROGRESS 1
    )
"@ +
            $data.Substring($match.Index + $match.Length)

Remove-Item -Path $cmakelistsFilePath
Set-Content -Path $cmakelistsFilePath -Value $new_data

Write-Host "The changes were applied to the CMakeLists.txt successfully."