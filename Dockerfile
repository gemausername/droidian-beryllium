# Dockerfile for Droidian Poco F1 Build Environment
# This Dockerfile creates a complete build environment for Droidian

FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install base packages
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    gnupg \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    lsb-release \
    sudo \
    nano \
    vim \
    htop \
    tree \
    jq \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh

# Install Android SDK platform-tools
RUN apt-get update && apt-get install -y \
    android-tools-adb \
    android-tools-fastboot \
    && rm -rf /var/lib/apt/lists/*

# Install Droidian build dependencies
RUN apt-get update && apt-get install -y \
    debootstrap \
    dosfstools \
    e2fsprogs \
    fdisk \
    gdisk \
    git \
    jq \
    libglib2.0-bin \
    libglib2.0-dev \
    libsystemd-dev \
    linux-packaging-snippets \
    mmdebstrap \
    mtools \
    parted \
    python3 \
    python3-pyaml \
    qemu-user-static \
    systemd-container \
    systemd-sysv \
    wget \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install debos
RUN apt-get update && apt-get install -y \
    debos \
    && rm -rf /var/lib/apt/lists/*

# Create build user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /build

# Copy build scripts
COPY scripts/ /build/scripts/
COPY kernel/ /build/kernel/
COPY packages/ /build/packages/
COPY rootfs/ /build/rootfs/

# Make scripts executable
RUN chmod +x /build/scripts/*.sh
RUN chmod +x /build/rootfs/*.sh

# Switch to build user
USER builder

# Default command
CMD ["/bin/bash"]
