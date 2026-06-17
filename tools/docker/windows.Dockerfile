# escape=`

# Use a specific, pinned base image for reproducibility
ARG REPO=mcr.microsoft.com/dotnet/framework/runtime
FROM $REPO:4.8-20260414-windowsservercore-ltsc2019

# Use cmd as default shell for VS install (Microsoft best practice)
# This ensures correct batch processing during VS bootstrapper execution
SHELL ["cmd", "/S", "/C"]

# Copy the Install.cmd helper script (Microsoft best practice)
# Handles exit code 3010 (reboot required) as success, and collects logs on failure
COPY ./tools/Install.cmd C:\TEMP\

# Download the VS log collector in case of install failure (Microsoft best practice)
ADD https://aka.ms/vscollect.exe C:\TEMP\collect.exe

# Pin the VS 2022 release channel for reproducible builds
ARG CHANNEL_URL=https://aka.ms/vs/17/release/channel
ADD ${CHANNEL_URL} C:\TEMP\VisualStudio.chman

# Install Visual Studio 2022 Build Tools with C++ components required by 3D Slicer:
#   - VCTools workload (core C++ build tools)
#   - MSVC v143 toolset (VS2022 x64)
#   - MSVC v143 14.39 toolset - pinned version known to work with VTK/ITK
#   - VC++ Redistributable (msvcp140.dll etc) - required for CMake try_run
#   - Windows10SDK.18362 - installs runtime redist DLLs only (NOT the full SDK headers/libs)
#     The full SDK is installed separately below via winsdksetup.exe
# NOTE: VisualStudio.chman is copied to C:\VS before TEMP cleanup so that vswhere.exe
#       can validate the instance registration (it checks channelUri path exists)
RUN curl -SL --output C:\TEMP\vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    && (call C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --channelUri C:\TEMP\VisualStudio.chman `
        --installChannelUri C:\TEMP\VisualStudio.chman `
        --add Microsoft.VisualStudio.Workload.VCTools `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64) `
    && exit /b 0

RUN (call C:\TEMP\Install.cmd C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --channelUri C:\TEMP\VisualStudio.chman `
        --installChannelUri C:\TEMP\VisualStudio.chman `
        --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest  `
        --add Microsoft.VisualStudio.Component.VC.14.39.17.12.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows10SDK.20348) `
    && del /q C:\TEMP\vs_buildtools.exe `
    && if not exist "C:\VS" md "C:\VS" `
    && copy /y C:\TEMP\VisualStudio.chman C:\VS\VisualStudio.chman `
    && powershell -NoProfile -Command "Get-Process -Name vs_installer,vs_buildtools,setup -ErrorAction SilentlyContinue | Wait-Process -Timeout 120 -ErrorAction SilentlyContinue; Start-Sleep -Seconds 3" `
    && (if exist "%TEMP%" rd /s /q "%TEMP%" 2>nul) `
    && (if not exist "%TEMP%" md "%TEMP%") `
    && exit /b 0

# Switch to PowerShell for remaining steps
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Set PowerShell execution policy
RUN Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Clean up VS package cache to reduce layer size.
# IMPORTANT: preserve _Instances folder - vswhere.exe reads it to detect VS installations.
# Deleting _Instances causes vswhere to return [] and CMake cannot find the compiler.
RUN if (Test-Path 'C:\ProgramData\Microsoft\VisualStudio\Packages') { `
        Get-ChildItem 'C:\ProgramData\Microsoft\VisualStudio\Packages' `
            | Where-Object { $_.Name -ne '_Instances' } `
            | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue `
    }

# Patch state.json channelUri to point to the permanent copy of VisualStudio.chman.
# vswhere.exe validates that the channelUri path exists before reporting an instance.
# C:\TEMP was cleaned up above so we redirect it to C:\VS\VisualStudio.chman.
# Uses literal string replace (not regex) to correctly handle JSON double-backslash encoding.
RUN $instanceBase = 'C:\ProgramData\Microsoft\VisualStudio\Packages\_Instances'; `
    Get-ChildItem $instanceBase -Directory -ErrorAction SilentlyContinue | ForEach-Object { `
        $f = ($_.FullName + '\state.json'); `
        if (Test-Path $f) { `
            $content = [System.IO.File]::ReadAllText($f); `
            $content = $content.Replace('C:\\TEMP\\VisualStudio.chman', 'C:\\VS\\VisualStudio.chman'); `
            [System.IO.File]::WriteAllText($f, $content); `
            Write-Host ('Patched channelUri in ' + $f) `
        } `
    }

# Install the full Windows 10 SDK 20348 (headers + libraries).
RUN curl.exe -SL --output C:\TEMP\winsdksetup.exe https://go.microsoft.com/fwlink/?linkid=2164145; `
    Start-Process -FilePath 'C:\TEMP\winsdksetup.exe' -Wait -ArgumentList `
        '/quiet', '/norestart', '/features', 'OptionId.DesktopCPPx64'; `
    Remove-Item 'C:\TEMP\winsdksetup.exe' -Force -ErrorAction SilentlyContinue; `
    $sdkDirs = (Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ', '; `
    Write-Host ('Windows Kits 10 contents: ' + $sdkDirs)

# Enable long paths (required by Slicer build - paths exceed 260 chars)
RUN New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Install Qt 5.15.2 with all components required by Slicer:
RUN curl.exe -L 'https://download.qt.io/archive/online_installers/4.4/qt-unified-windows-x64-4.4.1-online.exe' --output 'C:\TEMP\qt-installer.exe'; `
    cmd /C 'C:\TEMP\qt-installer.exe' install `
        qt.qt5.5152.win64_msvc2019_64 `
        qt.qt5.5152.qtwebengine `
        qt.qt5.5152.qtwebengine.win64_msvc2019_64 `
        qt.qt5.5152.qtscript `
        qt.qt5.5152.qtscript.win64_msvc2019_64 `
        qt.qt5.5152.qtwebglplugin.win64_msvc2019_64 `
        qt.qt5.5152.qtvirtualkeyboard.win64_msvc2019_64 `
        qt.qt5.5152.qtquicktimeline.win64_msvc2019_64 `
        qt.qt5.5152.qtquick3d.win64_msvc2019_64 `
        qt.qt5.5152.qtpurchasing.win64_msvc2019_64 `
        qt.qt5.5152.qtnetworkauth.win64_msvc2019_64 `
        qt.qt5.5152.qtlottie.win64_msvc2019_64 `
        qt.qt5.5152.qtdatavis3d.win64_msvc2019_64 `
        qt.qt5.5152.qtcharts.win64_msvc2019_64 `
        qt.qt5.5152.debug_info.win64_msvc2019_64 `
        --root C:\Qt `
        --auto-answer telemetry-question=No,AssociateCommonFiletypes=Yes `
        --accept-licenses --accept-obligations `
        --email giknakotru@vusra.com --pw LTRACEltrace123 `
        --confirm-command --accept-messages `
        --filter-packages 'DisplayName=Qt 5.15.2'; `
    Remove-Item 'C:\TEMP\qt-installer.exe' -Force -ErrorAction SilentlyContinue

# Install Chocolatey (pinned version for reproducibility)
ENV ChocolateyUseWindowsCompression=false
ENV chocolateyVersion=1.4.0
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install build prerequisites via Chocolatey (all pinned for reproducibility)
# git >= 1.7.10 required by Slicer; cmake >= 3.20.6 required (avoiding known bad versions)
# Note: cmake 3.21.0, 3.25.0-3.25.2 have known Slicer build issues - 3.27.4 is safe
RUN choco install git     --version=2.42.0 -y
RUN choco install cmake   --version=3.27.4 -y
RUN choco install 7zip    --version=23.1.0 -y
RUN choco install nsis    --version=3.09   -y
RUN choco install python  --version=3.12.9 -y

# Install Python packages
RUN python -m pip install --upgrade pip==25.3
COPY ./tools/requirements.txt c:/geoslicerbase/tools/requirements.txt
RUN python -m pip install -r c:/geoslicerbase/tools/requirements.txt

# Copy VC++ Runtime DLLs to System32 so CMake try_run and superbuild
# executables (e.g. CTK dgraph.exe) can find them without PATH tricks.
# - VC redist: search recursively for msvcp140.dll to handle any version subfolder name
# - UCRT: skip files already present in System32 (protected OS files that cannot be overwritten)
RUN $vcRedistBase = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC'; `
    $vcRedist = Get-ChildItem $vcRedistBase -Recurse -Filter 'msvcp140.dll' -ErrorAction SilentlyContinue `
        | Select-Object -First 1 `
        | ForEach-Object { $_.DirectoryName }; `
    if ($vcRedist) { `
        Copy-Item ($vcRedist + '\*.dll') 'C:\Windows\System32\' -Force -ErrorAction SilentlyContinue; `
        Write-Host ('Copied VC redist from ' + $vcRedist) `
    } else { `
        Write-Host 'WARNING: msvcp140.dll not found under VS Redist - skipping' `
    }; `
    $ucrtPath = 'C:\Program Files (x86)\Windows Kits\10\Redist\ucrt\DLLs\x64'; `
    if (Test-Path $ucrtPath) { `
        Get-ChildItem ($ucrtPath + '\*.dll') | ForEach-Object { `
            if (-not (Test-Path ('C:\Windows\System32\' + $_.Name))) { `
                Copy-Item $_.FullName 'C:\Windows\System32\' -Force `
            } `
        }; `
        Write-Host 'Copied non-existing UCRT DLLs to System32' `
    } else { `
        Write-Host 'WARNING: UCRT path not found - skipping' `
    }

# Add all required tools to PATH
# - Git (git.exe and patch.exe required by Slicer CMake)
# - CMake, 7-Zip
# - MSBuild (required by cmake --build with VS generator)
# - VS Installer (contains vswhere.exe used by CMake for VS detection)
RUN [Environment]::SetEnvironmentVariable('PATH', ($env:PATH + `
    ';' + $env:ProgramFiles + '\Git\bin' + `
    ';' + $env:ProgramFiles + '\Git\usr\bin' + `
    ';' + $env:ProgramFiles + '\CMake\bin' + `
    ';' + $env:ProgramFiles + '\7-Zip' + `
    ';' + ${env:ProgramFiles(x86)} + '\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin' + `
    ';' + ${env:ProgramFiles(x86)} + '\Microsoft Visual Studio\Installer'), `
    [System.EnvironmentVariableTarget]::Machine)

# Set explicit executable paths required by Slicer's CMake configuration
RUN [Environment]::SetEnvironmentVariable('GIT_EXECUTABLE',   ($env:ProgramFiles + '\Git\bin\git.exe'),       [System.EnvironmentVariableTarget]::Machine); `
    [Environment]::SetEnvironmentVariable('Patch_EXECUTABLE', ($env:ProgramFiles + '\Git\usr\bin\patch.exe'), [System.EnvironmentVariableTarget]::Machine)

# Set CMake generator environment variables:
# - CMAKE_GENERATOR: must be set for CMAKE_GENERATOR_INSTANCE to be respected
# - CMAKE_GENERATOR_INSTANCE: explicit VS install path, bypasses vswhere as fallback
# - CMAKE_GENERATOR_TOOLSET: pins MSVC v143 with the 14.39 compiler version
# - WindowsSdkDir/WindowsSDKVersion: ensures MSBuild finds the SDK
RUN [Environment]::SetEnvironmentVariable('CMAKE_GENERATOR', `
        'Visual Studio 17 2022', [System.EnvironmentVariableTarget]::Machine); `
    [Environment]::SetEnvironmentVariable('CMAKE_GENERATOR_INSTANCE', `
        (${env:ProgramFiles(x86)} + '\Microsoft Visual Studio\2022\BuildTools'), [System.EnvironmentVariableTarget]::Machine); `
    [Environment]::SetEnvironmentVariable('CMAKE_GENERATOR_TOOLSET', `
        'v143,version=14.39', [System.EnvironmentVariableTarget]::Machine); `
    $sdkRoot = 'C:\Program Files (x86)\Windows Kits\10'; `
    $sdkVer = (Get-ChildItem ($sdkRoot + '\Include') -Directory -ErrorAction SilentlyContinue `
        | Where-Object { $_.Name -match '^\d' } `
        | Sort-Object Name -Descending `
        | Select-Object -First 1).Name; `
    if (-not $sdkVer) { $sdkVer = '10.0.20348.0' }; `
    [Environment]::SetEnvironmentVariable('WindowsSdkDir', ($sdkRoot + '\'), [System.EnvironmentVariableTarget]::Machine); `
    [Environment]::SetEnvironmentVariable('WindowsSDKVersion', ($sdkVer + '\'), [System.EnvironmentVariableTarget]::Machine); `
    Write-Host ('Windows SDK version set to: ' + $sdkVer)

WORKDIR /geoslicerbase

RUN git config --global --add safe.directory C:/geoslicerbase; `
    git config --global --add safe.directory '*'

# Build arguments and environment variables passed at build time
ARG SLICER_GIT_COMMIT
ENV SLICER_GIT_COMMIT=$SLICER_GIT_COMMIT

ARG THREADS
ENV THREADS=$THREADS

ARG BUILD_TYPE
ENV BUILD_TYPE=$BUILD_TYPE

ENV PYTHONUNBUFFERED=1
ENV PIP_DEFAULT_TIMEOUT=100
ENV USING_DOCKER=1

WORKDIR /

# Keep container alive (ping loop) so docker-compose exec can run the build
CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]
