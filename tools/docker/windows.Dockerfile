FROM python:3.9.7-windowsservercore as base

# Change shell to prompt terminal as default shell for the followings commands
SHELL ["cmd", "/S", "/C"]

# Install Visual Studio C++ & Build tools
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe && \
    start /w vs_buildtools.exe --quiet --wait --norestart --includeRecommended --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 && \
    del /q vs_buildtools.exe

RUN curl -SL --output vs_community.exe https://aka.ms/vs/17/release/vs_community.exe && \
    start /w vs_community.exe --quiet --wait --norestart --nocache --includeRecommended --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community" --add Microsoft.Component.MSBuild --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 && \
    del /q vs_community.exe

# Change shell to powershell as default shell for the followings commands
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

# Read arguments related to OCI credentials
ARG OCI_CONFIG
ARG OCI_API_KEY_PUBLIC
ARG OCI_API_KEY

ENV OCI_CONFIG $OCI_CONFIG
ENV OCI_API_KEY_PUBLIC $OCI_API_KEY_PUBLIC
ENV OCI_API_KEY $OCI_API_KEY

# Install OCI credentials
RUN mkdir "$env:userprofile\\.oci"; \ 
    $oci_folder = "$env:userprofile + '\' + '.oci'" ; \ 
    $config_file_path = "$oci_folder + '\' + 'config'" ; \ 
    $oci_api_key_public_file_path =  "$oci_folder + '\' + 'oci_api_key_public.pem'"; \ 
    $oci_api_key_file_path =  "$oci_folder + '\' + 'oci_api_key.pem'"; \ 
    [IO.File]::WriteAllLines($config_file_path, $ENV:OCI_CONFIG) ; \
    [IO.File]::WriteAllLines($oci_api_key_public_file_path, $ENV:OCI_API_KEY_PUBLIC) ; \
    [IO.File]::WriteAllLines($oci_api_key_file_path, $ENV:OCI_API_KEY)

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
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 

# Install packages from Chocolatey
RUN choco install git.install -y 
RUN choco install 7zip.install -y
RUN choco install cmake --version=3.22.1 -y
RUN choco install nsis --version=3.07 -y

# Enable long path
RUN New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Install CUDA
RUN curl.exe -L 'https://objectstorage.sa-saopaulo-1.oraclecloud.com/p/jIBqg1698YUbQelonErDUso7SREleH2foxQw5W1CDyxmZTeCrkFxBNizA0c8d3tx/n/grrjnyzvhu1t/b/share/o/GeoSlicer/NVIDIA%20GPU%20Computing%20Toolkit.zip' --output cuda_files.zip ; \
    Expand-Archive -Force -LiteralPath '.\cuda_files.zip' -DestinationPath "$env:programfiles" ; \
    $env:CUDA_PATH_V11_2 = "$env:programfiles + '\NVIDIA GPU Computing Toolkit\CUDA\v11.2'" ; \
    [Environment]::SetEnvironmentVariable('CUDA_PATH_V11_2', "$env:programfiles + '\NVIDIA GPU Computing Toolkit\CUDA\v11.2'", [System.EnvironmentVariableTarget]::Machine) ; \
    Remove-Item cuda_files.zip

# Add git/bin to path (bash)
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + $env:programfiles + '\Git\usr\bin\'", [System.EnvironmentVariableTarget]::Machine)

# Add msbuild to path
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + ${env:programfiles(x86)} + '\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin'", [System.EnvironmentVariableTarget]::Machine)

# Add cmake to path
RUN [Environment]::SetEnvironmentVariable('PATH', "$env:PATH + ';' + $env:programfiles + '\CMake\bin'", [System.EnvironmentVariableTarget]::Machine)

# Add environment variables related to Slicer build
RUN [Environment]::SetEnvironmentVariable('GIT_EXECUTABLE', "$env:programfiles + '\Git\bin\git.exe'", [System.EnvironmentVariableTarget]::Machine)
RUN [Environment]::SetEnvironmentVariable('Patch_EXECUTABLE', "$env:programfiles + '\Git\usr\bin\patch.exe'", [System.EnvironmentVariableTarget]::Machine) 

# Update pip
RUN python -m pip install --upgrade pip==22.0.2

WORKDIR /geoslicerbase

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory C:/geoslicerbase

ARG SLICER_GIT_COMMIT
ENV SLICER_GIT_COMMIT $SLICER_GIT_COMMIT

ARG THREADS
ENV THREADS $THREADS

ARG BUILD_TYPE
ENV BUILD_TYPE $BUILD_TYPE

ENV PYTHONUNBUFFERED 1
ENV PIP_DEFAULT_TIMEOUT 100

FROM base as image-dev
# As development image: Mount repository to avoid copying and keep container running forever

WORKDIR /

CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]

FROM base as image-prod
# As production image: Copy all context and keep container running forever

COPY . .

WORKDIR /

RUN python ./geoslicerbase/tools/update_cmakelists_content.py --commit $ENV:SLICER_GIT_COMMIT

# Build and pack application
RUN python ./geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --type $ENV:BUILD_TYPE --jobs $ENV:THREADS


CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]