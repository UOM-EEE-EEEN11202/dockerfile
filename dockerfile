# Set base OS
# FROM ubuntu:latest # should use this, but still picks up 22.04 for some reason, so hard coding to use 24.04 for now 
FROM ubuntu:24.04

# Install git, C/C++, and Python and requirements. (Rust is installed below)
USER root
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install build-essential gdb cmake cppcheck curl \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git-all expect
ENV RUNNING_IN_DOCKER=true
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install python3.12 python3.12-venv python3-pip

# Remove default user ubuntu. Assumes using 23.04 or newer (no checks are present)
RUN touch /var/mail/ubuntu \
    && chown ubuntu /var/mail/ubuntu \
    && userdel -r ubuntu

# Set user of the container
ARG USERNAME=vscode	
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
	
# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

# Install Rust as user rather than as root. Makes the path/permissions easier
USER ${USERNAME}
RUN curl --proto "https" --tlsv1.2 https://sh.rustup.rs -sSf | /bin/bash -s -- -y
ENV PATH="~/.cargo/bin:${PATH}"

# TODO:
# Fix latest.
# [39371 ms] Start: Run in container: git config --global --add safe.directory /workspaces/devcontainer-main