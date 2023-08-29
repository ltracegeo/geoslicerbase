FROM slicer/slicer-base:latest as base

# Update pip
RUN python -m pip install --upgrade pip==22.0.2

# Install tools dependencies
COPY ./tools/requirements.txt ./tools/requirements.txt
RUN python -m pip install -r ./tools/requirements.txt

# Config git
RUN git config --global --add safe.directory /geoslicerbase

WORKDIR /

CMD ["sh", "-c", "tail -f /dev/null"]