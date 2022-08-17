FROM python:3.9.7-windowsservercore as base

# Change shell to prompt terminal as default shell for the followings commands
SHELL ["cmd", "/S", "/C"]

# Install Visual Studio C++ & Build tools
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe && \
    start /w vs_buildtools.exe --quiet --wait --norestart --includeRecommended --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 && \
    del /q vs_buildtools.exe

RUN curl -SL --output vs_community.exe https://aka.ms/vs/17/release/vs_community.exe && \
    start /w vs_community.exe --quiet --wait --norestart --nocache --includeRecommended --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\Community" --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 && \
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

# Install Chocolatey
ENV ChocolateyUseWindowsCompression false
RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) 

# Install packages from Chocolatey
RUN choco install git.install -y 
RUN choco install 7zip.install -y

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
RUN [Environment]::SetEnvironmentVariable('PATH', "${env:programfiles(x86)} + '\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin'", [System.EnvironmentVariableTarget]::Machine)

WORKDIR /geoslicerbase

# Update pip
RUN python -m pip install --upgrade pip==22.0.2

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory C:/geoslicerbase

FROM base as image-dev
# As development image: Mount repository to avoid copying and keep container running forever
CMD ["cmd", "/c", "ping", "-t", "localhost", ">", "NUL"]

FROM base as image-prod
# As production image: Copy all context and do the things

COPY . .

# Update CMakeLists content
RUN $ls_remote_result = git ls-remote git@bitbucket.org:ltrace/slicer.git master ; \
    $slicer_repo_commit_tag = ($ls_remote_result -split '\\s+')[0] ; \
    python ./tools/update_cmakelists_content.py --commit f621c429c930aa3f59425560e4b2fddea44178b5

# Build and pack application
RUN python ./tools/build_and_pack.py --source . --jobs 42 --type Release --no-export