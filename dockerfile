# Set base OS
FROM ubuntu:latest
# FROM ubuntu:24.04

# Install git, C/C++, and Python and requirements. (Rust is installed below)
USER root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
         build-essential gdb cmake cppcheck \
         git-all expect \
         curl \
         python3.12 python3.12-venv python3-pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
ENV RUNNING_IN_DOCKER=true


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
RUN update-locale LC_ALL=en_GB.UTF-8 LANG=en_GB.UTF-8


# Install Rust and UV as user rather than as root. Makes the path/permissions easier
USER ${USERNAME}
RUN curl --proto "https" --tlsv1.2 https://sh.rustup.rs -sSf | /bin/bash -s -- -y
ENV PATH="~/.cargo/bin:${PATH}"

# If getting from script. We use a git container version instead
# RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# ENV PATH="~/.local/bin:${PATH}"
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=manual \
    UV_PYTHON=python3.12
#   UV_PROJECT_ENVIRONMENT=/workspaces/project


# Add meta-data
LABEL org.opencontainers.image.source=https://github.com/UOM-EEE-EEEN1XXX2/dockerfile
LABEL org.opencontainers.image.description="Python, Rust, and C/C++ container for EEEN1XXX2 programming course"
LABEL org.opencontainers.image.licenses=MIT
