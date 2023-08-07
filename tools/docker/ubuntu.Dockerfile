FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04 as base

ENV OCI_CONFIG_FILE $HOME/.oci/config
ENV PYTHONUNBUFFERED 1
ENV PIP_DEFAULT_TIMEOUT 100

# Define image time zone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#  Install linux environment requirements
RUN apt update -y && \
    apt autoclean -y && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y git subversion build-essential cmake cmake-curses-gui cmake-qt-gui \
        qt5-default qtmultimedia5-dev qttools5-dev libqt5xmlpatterns5-dev libqt5svg5-dev qtwebengine5-dev qtscript5-dev \
        qtbase5-private-dev libqt5x11extras5-dev libxt-dev curl

# Install python 3.9
RUN apt install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install -y python3.9 python3-pip python3.9-dev

# Use python3.9 as python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 10
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10

# Install Qt 
RUN curl -LO http://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run && \
    chmod +x qt-unified-linux-x64-online.run && \
    ./qt-unified-linux-x64-online.run \
        install \
            qt.qt5.5152.gcc_64 \
            qt.qt5.5152.qtscript \
            qt.qt5.5152.qtscript.gcc_64 \
            qt.qt5.5152.qtwebengine \
            qt.qt5.5152.qtwebengine.gcc_64 \
        --root /opt/qt \
        --email giknakotru@vusra.com \
        --pw LTRACEltrace123 \
        --auto-answer telemetry-question=No,AssociateCommonFiletypes=Yes \
        --accept-licenses --accept-obligations --confirm-command --accept-messages

# Install 7z
RUN apt install -y p7zip-full p7zip-rar 

# Install dependencies for GUI display
RUN apt-get update \
  && apt install -y -qq --no-install-recommends libglu1-mesa libpulse-dev libnss3 libxdamage-dev libxcursor-dev libasound2 libglvnd0 libgl1 libglx0 libegl1 libxext6 libx11-6 \
  && rm -rf /var/lib/apt/lists/*

# Environment variables for the nvidia-container-runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute

# set home directory allow access to "user" folder
WORKDIR /geoslicerbase

# Update pip
RUN python -m pip install --upgrade pip==22.0.2

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory /geoslicerbase

ARG SLICER_GIT_COMMIT
ENV SLICER_GIT_COMMIT $SLICER_GIT_COMMIT

ARG THREADS
ENV THREADS $THREADS

ARG BUILD_TYPE
ENV BUILD_TYPE $BUILD_TYPE

FROM base as image-dev
# As development image: Mount repository to avoid copying and keep container running forever

WORKDIR /

CMD ["sh", "-c", "tail -f /dev/null"]

FROM base as image-prod
# As production image: Copy all context and keep container running forever

COPY . .

WORKDIR /

RUN python ./geoslicerbase/tools/update_cmakelists_content.py --commit $ENV:SLICER_GIT_COMMIT

# Build and pack application
RUN python ./geoslicerbase/tools/build_and_pack.py --source ./geoslicerbase --type $ENV:BUILD_TYPE --jobs $ENV:THREADS


CMD ["sh", "-c", "tail -f /dev/null"]