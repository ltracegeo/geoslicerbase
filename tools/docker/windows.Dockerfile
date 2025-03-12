ARG REPO=mcr.microsoft.com/dotnet/framework/runtime
FROM $REPO:4.8-20230808-windowsservercore-ltsc2019

# Change shell to powershell as default shell for the followings commands
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

# Set your PowerShell execution policy
RUN Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Install Qt
RUN $exePath = "$env:TEMP + '\qt-unified-windows-x64-4.4.1-online.exe'" ; \ 
    curl.exe -L 'https://download.qt.io/archive/online_installers/4.4/qt-unified-windows-x64-4.4.1-online.exe' --output "$exePath" ; \
    cmd /C "$exePath" install qt.qt5.5152.qtwebengine qt.qt5.5152.qtscript qt.qt5.5152.win64_msvc2019_64 \ 
        qt.qt5.5152.qtwebglplugin.win64_msvc2019_64 qt.qt5.5152.qtwebengine.win64_msvc2019_64 qt.qt5.5152.qtvirtualkeyboard.win64_msvc2019_64 \
        qt.qt5.5152.qtscript.win64_msvc2019_64 qt.qt5.5152.qtquicktimeline.win64_msvc2019_64 qt.qt5.5152.qtquick3d.win64_msvc2019_64 \
        qt.qt5.5152.qtpurchasing.win64_msvc2019_64 qt.qt5.5152.qtnetworkauth.win64_msvc2019_64 qt.qt5.5152.qtlottie.win64_msvc2019_64 \
        qt.qt5.5152.qtdatavis3d.win64_msvc2019_64 qt.qt5.5152.qtcharts.win64_msvc2019_64 qt.qt5.5152.debug_info.win64_msvc2019_64 \
        --root C:\Qt --auto-answer telemetry-question=No,AssociateCommonFiletypes=Yes --accept-licenses --accept-obligations \ 
        --email giknakotru@vusra.com --pw LTRACEltrace123 --confirm-command --accept-messages --filter-packages "DisplayName=Qt 5.15.2"

# Install Chocolatey
ENV ChocolateyUseWindowsCompression false
ENV chocolateyVersion=1.4.0
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 

# Install packages from Chocolatey
RUN choco install git --version=2.42.0 -y 
RUN choco install 7zip --version=23.1.0 -y
RUN choco install cmake --version=3.27.4 -y
RUN choco install nsis --version=3.09 -y

# Enable long path
RUN New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Change shell to prompt terminal as default shell for the followings commands
SHELL ["cmd", "/S", "/C"]
RUN set filePath=%TEMP%\cuda_files.zip && \
    curl -fSLo %filePath% "https://objectstorage.sa-saopaulo-1.oraclecloud.com/p/jIBqg1698YUbQelonErDUso7SREleH2foxQw5W1CDyxmZTeCrkFxBNizA0c8d3tx/n/grrjnyzvhu1t/b/share/o/GeoSlicer/NVIDIA%20GPU%20Computing%20Toolkit.zip" && \
    7z x %filePath% -o%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v11.2 && \
    set CUDA_PATH_V11_2=%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v11.2 && \
    setx CUDA_PATH_V11_2 "%ProgramFiles%\NVIDIA GPU Computing Toolkit\CUDA\v11.2" /M && \
    del %filePath%

# Change shell to powershell as default shell for the followings commands
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

RUN choco install visualstudio2019buildtools -y --package-parameters "--quiet --wait --norestart --includeOptional"
RUN choco install visualstudio2019-workload-vctools -y --package-parameters "--quiet --wait --norestart --includeOptional"

# Add git/bin to path (bash)
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + $env:programfiles + '\Git\usr\bin\'", [System.EnvironmentVariableTarget]::Machine)

# Add msbuild to path
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + ${env:programfiles(x86)} + '\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin'", [System.EnvironmentVariableTarget]::Machine)

# Add cmake to path
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + $env:programfiles + '\CMake\bin'", [System.EnvironmentVariableTarget]::Machine)

# Add 7zip to path
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + $env:programfiles + '\7-zip\'", [System.EnvironmentVariableTarget]::Machine)

# Add environment variables related to Slicer build
RUN [Environment]::SetEnvironmentVariable('GIT_EXECUTABLE', "$env:programfiles + '\Git\bin\git.exe'", [System.EnvironmentVariableTarget]::Machine)
RUN [Environment]::SetEnvironmentVariable('Patch_EXECUTABLE', "$env:programfiles + '\Git\usr\bin\patch.exe'", [System.EnvironmentVariableTarget]::Machine) 

WORKDIR /geoslicerbase

# Config git
RUN git config --global --add safe.directory C:/geoslicerbase

# Environment variables
ARG SLICER_GIT_COMMIT
ENV SLICER_GIT_COMMIT $SLICER_GIT_COMMIT

ARG THREADS
ENV THREADS $THREADS

ARG BUILD_TYPE
ENV BUILD_TYPE $BUILD_TYPE

ENV PYTHONUNBUFFERED 1
ENV PIP_DEFAULT_TIMEOUT 100

RUN git config --global --add safe.directory '*'

WORKDIR /

CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]