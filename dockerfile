# Set versions
ARG UV_VERSION=0.12.1
ARG PYTHON_VERSION=3.14
ARG RUST_VERSION=1.97.0
ARG UBUNTU_VERSION=26.04
# ARG UBUNTU_VERSION=latest


# Set default username. Devcontainer need to match this with the user in devcontainer.json for correct permissions
ARG USERNAME=vscode


# Dedicated stage for uv binary (workaround for COPY --from variable expansion limits)
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv-binary


# Set base OS
FROM ubuntu:${UBUNTU_VERSION}


# Use a stricter shell for RUN commands.
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]


# Set user of the container.
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}"


# Install git, C/C++, Python, and locale setup in one layer.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        wget \
        build-essential gdb \
        cmake \
        clang clangd lld llvm lldb \
        git expect \
        curl \
        "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-venv" "python${PYTHON_VERSION}-dev" python3-pip \
        jq \
        vim \
        dos2unix \
    && sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_GB.UTF-8 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_GB.UTF-8
ENV RUNNING_IN_DOCKER=true


# Used to persist bash history as per
# https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R "${USERNAME}" /commandhistory \
    && echo "${SNIPPET}" >> "/home/${USERNAME}/.bashrc"


# Install uv from a pinned image stage for better reproducibility.
COPY --from=uv-binary /uv /usr/local/bin/uv
ENV UV_LINK_MODE=copy \
    UV_PYTHON=python${PYTHON_VERSION} \
    UV_PYTHON_DOWNLOADS=automatic


# Install Rust as user rather than as root. Makes path/permissions easier.
USER ${USERNAME}
RUN curl --proto "https" --tlsv1.2 https://sh.rustup.rs -sSf | /bin/bash -s -- -y --default-toolchain="${RUST_VERSION}" --profile=minimal
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"


# Add meta-data
LABEL org.opencontainers.image.version="v2627.0.0" \
      org.opencontainers.image.authors="Alex Casson <alex.casson@manchester.ac.uk>" \
      org.opencontainers.image.title="EEEN11202 dockerfile" \
      org.opencontainers.image.source="https://github.com/UOM-EEE-EEEN11202/dockerfile" \
      org.opencontainers.image.description="Python, Rust, and C/C++ container for EEEN11202 programming course" \
      org.opencontainers.image.licenses="MIT"
