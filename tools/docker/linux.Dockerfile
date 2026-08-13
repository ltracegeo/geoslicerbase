FROM slicer/slicer-base:latest as base 


ARG USER_ID=1000
ARG GROUP_ID=1000

RUN groupadd -g ${GROUP_ID} ltrace && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -m -s /bin/bash ltrace

RUN dnf install -y openssh-clients 

# Update pip
RUN python -m pip install --upgrade pip

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory /geoslicerbase

WORKDIR /

RUN git config --global --add safe.directory '*'

RUN rm -f /usr/bin/ld.gold
USER ltrace
ENV USING_DOCKER=1
CMD ["sh", "-c", "tail -f /dev/null"]