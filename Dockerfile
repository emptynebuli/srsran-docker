FROM ubuntu:latest as base

# Install dependencies
# We need uhd so enb and ue are built
# Use curl and unzip to get a specific commit state from github
# Also install ping to test connections
RUN DEBIAN_FRONTEND=noninteractive apt update && apt install -y \
     build-essential \
     binutils-dev \
     cmake \
     libfftw3-dev \
     libmbedtls-dev \
     libdw-dev \
     libboost-program-options-dev \
     libconfig++-dev \
     libdwarf-dev \
     libsctp-dev \
     soapysdr-module-bladerf \
     soapysdr-tools \
     libsoapysdr-dev \
     libpcsclite-dev \
     libusb-1.0-0-dev \
     libusb-1.0-0 build-essential \
     iputils-ping \
     iproute2 \
     iptables \
     git

RUN apt clean autoclean && \
    apt autoremove --yes && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /bladerf

# Download and build bladeRF
RUN git clone https://github.com/Nuand/bladeRF.git ./
WORKDIR /bladerf/host/build
RUN cmake ../ && \
    make && \
    make install && \
    ldconfig && \
    rm -rf /bladerf

WORKDIR /srsran

# Download and build srsRAN
RUN git clone https://github.com/srsran/srsRAN_4G.git ./
WORKDIR /srsran/build
RUN cmake ../ && \
    make && \
    make test && \
    make install && \
    srsran_install_configs.sh service && \
    ldconfig && \
    rm -rf /srsran

WORKDIR /
