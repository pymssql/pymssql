$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function MSVC-Env-Invoke([string] $command)
{
    $command = "$env:COMSPEC /E:ON /V:ON /C $PSScriptRoot\run_with_env.cmd " + $command
    $output = Invoke-Expression -Command:$command
    Write-Output $output
    if ($LastExitCode -ne 0) { exit $LastExitCode }
}

Function Ensure-Dir([string] $Path)
{
    if (-not (Test-Path -Path $Path))
    {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

Function Cached-Download([string] $Url, [string] $OutputFile)
{
    if (-not (Test-Path -Path $OutputFile))
    {
        Write-Verbose "Downloading $OutputFile from '$Url' ..."
        (New-Object System.Net.WebClient).DownloadFile($Url, $OutputFile)
    }
}

set-alias extract "$env:ProgramFiles\7-Zip\7z.exe"

#
# Build win-iconv.
#
if (Test-Path env:WIN_ICONV_VERSION)
{
    $win_iconv_version = $env:WIN_ICONV_VERSION
}
else
{
    $win_iconv_version = "0.0.8"
    Write-Verbose "WIN_ICONV_VERSION not set; defaulting to $win_iconv_version"
}

$build_dir = "$PSScriptRoot\..\..\build"

if (Test-Path env:BUILD_INSTALL_PREFIX)
{
    $install_prefix = $env:BUILD_INSTALL_PREFIX
}
else
{
    $install_prefix = $build_dir
}

Ensure-Dir $build_dir
Ensure-Dir "$install_prefix\include"
Ensure-Dir "$install_prefix\lib"


$url = "https://codeload.github.com/win-iconv/win-iconv/zip/v$win_iconv_version"
$win_iconv_zip = "$build_dir\win-iconv-$win_iconv_version.zip"

Cached-Download $url $win_iconv_zip

$win_iconv_path = "win-iconv-$win_iconv_version"

if (-not (Test-Path -Path $win_iconv_path))
{
    # Requires PowerShell 5+.
    Write-Verbose "Expanding $win_iconv_zip ..."
    extract x -aoa "$win_iconv_zip" -o"$build_dir"
    if ($LastExitCode -ne 0) { exit $LastExitCode }
}

pushd "$build_dir\$win_iconv_path"

$cmake = "``
cmake -G ""NMake Makefiles"" ``
    -DBUILD_STATIC=on ``
    -DBUILD_SHARED=off ``
    -DBUILD_EXECUTABLE=off ``
    -DBUILD_TEST=on ``
    -DCMAKE_BUILD_TYPE=Release ``
    .
"

MSVC-Env-Invoke $cmake
MSVC-Env-Invoke 'nmake'

popd

# Copy lib and include files to common dir.
cp "$build_dir\$win_iconv_path\iconv.h" "$install_prefix\include"
cp "$build_dir\$win_iconv_path\*.lib" "$install_prefix\lib"
