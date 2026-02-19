# Set base OS
FROM ubuntu:latest
# FROM ubuntu:24.04


# Remove default user ubuntu. Assumes using 23.04 or newer (no checks are present)
RUN touch /var/mail/ubuntu \
    && chown ubuntu /var/mail/ubuntu \
    && userdel -r ubuntu


# Set user of the container
ARG USERNAME=vscode	
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

	
# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"


# Set locale
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales
RUN sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_GB.UTF-8
ENV LANG=en_GB.UTF-8 


# Install git, C/C++, and Python and requirements. (Rust is installed below)
USER root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \ 
    && apt-get update && apt-get -y install --no-install-recommends \
         wget apt-transport-https software-properties-common \
         build-essential gdb cmake cppcheck \
         clang clangd lld llvm lldb \
         git-all expect \
         curl \
         python3.12 python3.12-venv python3-pip python3.12-dev \
         jq \
         vim \
         dos2unix \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* \
ENV RUNNING_IN_DOCKER=true


# Install UV
ARG PYTHON_VERSION=3.14
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON=python${PYTHON_VERSION} \
    UV_PYTHON_DOWNLOADS=automatic


# Install Rust as user rather than as root. Makes the path/permissions easier
ARG RUST_VERSION=1.93.0
USER ${USERNAME}
RUN curl --proto "https" --tlsv1.2 https://sh.rustup.rs -sSf | /bin/bash -s -- -y --default-toolchain=${RUST_VERSION}
ENV PATH="~/.cargo/bin:${PATH}"


# Add meta-data
LABEL org.opencontainers.image.version="v2526.4.0" \
      org.opencontainers.image.authors="Alex Casson <alex.casson@manchester.ac.uk>" \
      org.opencontainers.image.title="EEEN11202 dockerfile" \
      org.opencontainers.image.source="https://github.com/UOM-EEE-EEEN11202/dockerfile" \
      org.opencontainers.image.description="Python, Rust, and C/C++ container for EEEN11202 programming course" \
      org.opencontainers.image.licenses="MIT"
