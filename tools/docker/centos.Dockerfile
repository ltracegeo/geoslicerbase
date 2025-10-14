FROM slicer/slicer-base:5.6 as base

# Update yum repository due to CentOS 7 EOL
COPY ./tools/docker/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

# Update pip
RUN python -m pip install --upgrade pip==22.3

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory /geoslicerbase

WORKDIR /

RUN git config --global --add safe.directory '*'

ENV USING_DOCKER=1
CMD ["sh", "-c", "tail -f /dev/null"]