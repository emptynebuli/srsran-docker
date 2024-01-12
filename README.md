# srsran-docker

> This is roughly based on the repo created by [davwheat](https://github.com/davwheat/srsRAN-docker-emulated)

This is a minimal example of [srsRAN_4G](https://github.com/srsran/srsRAN_4G) system running in a Docker environment. This particular build is designed around the use of bladeRF as the cellular antenna. Core network and base station all run in sepearte containers. This setup can support the user device but I have designed this setup to allow remote equipment to connect to this environment.

### Usage

Clone this repository, and build the initial image with the following command:

    $ docker-compose up srsepc

The initial build can take some time...

A shell script is provided in this repo to assist with starting the various components of this environment.

    $ ./srsran.sh 

    Usage:                    srsran.sh [METHOD] <OPTIONS>

    Method Options:
      srsepc                  Start srsEPC container
      srsenb                  Start srsENB container
      net-access              Activate INET access for srsEPC
      down                    Terminate srsRAN virtual environment

    Options:
      help                    List METHOD help options
      default                 List tool default options

This environment is designed with Docker's `ipvlan` driver for 802.1Q tagging for an Internet bound interface. These settings can be modified in the `docker-compose.yml` file to suite your required needs. This network driver is created and destroyed as part of the shell script through the `docker create` command. Modify the appropriate global options to suite your particular environment:

```
##################################
# Docker Options
##################################
DRIVER='ipvlan'
VLANID='20'
PARENT='eth0'
SUBNET='192.168.20.0/24'
```

Any modifications to the `DRIVER`/`VLANID` values will need to be updated in the `docker-compose.yml` file:

```
networks:
  ipvlan20:
    external: true
```

NOTE: `ipvlan20` is generated in the shell script from `${DRIVER}${VLANID}`.

Default configuration files for `srsRAN_4G` are provided in the `config` directory. These files have been modified to support the virtual network, detailed below, for intra-container communications:

```
networks:
  ...
  corenet:
    ipam:
      driver: default
      config:
        - subnet: 10.80.95.0/24
```

This script is based around the `WORKDIR` of `/opt/srsRAN`, if the install location is changed - the following modifications should be made:
* Update `WORKDIR` variable in `srsran.sh`
* Update directory mappings in `docker-compose.yml`