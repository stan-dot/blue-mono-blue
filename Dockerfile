# The devcontainer should use the developer target and run as root with podman
# or docker with user namespaces.
ARG UV_VERSION=0.5.3
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS developer

# Add any system dependencies for the developer/build environment here
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set up a virtual environment and put it in PATH
RUN python -m venv /venv
ENV PATH=/venv/bin:$PATH

# The build stage installs the context into the venv
FROM developer AS build
COPY . /context
WORKDIR /context
RUN touch dev-requirements.txt && pip install --upgrade pip && pip install -c dev-requirements.txt .

# The runtime stage copies the built venv into a slim runtime container
ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim AS runtime
# Add apt-get system dependecies for runtime here if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Git required for installing packages at runtime
    git \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /venv/ /venv/
ENV PATH=/venv/bin:$PATH

RUN mkdir -p /.cache/pip; chmod -R 777 /venv /.cache/pip

ENTRYPOINT ["blueapi"]
CMD ["serve"]
