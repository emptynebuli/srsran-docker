#!/bin/bash

##################################
# Global Options
##################################
WORKDIR="/opt/srsRAN/"

##################################
# Docker Options
##################################
DRIVER='ipvlan'
VLANID='20'
PARENT='eth0'
SUBNET='192.168.20.0/24'

##################################
# Virtual ENV Defaults
##################################
EPC_CMD='stdbuf -oL srsepc /etc/srsran/epc.conf --log.all_level debug --log.filename /logs/srsepc-'"$(date '+%Y-%m-%d_%H:%M:%S').log"
ENB_CMD='stdbuf -oL srsenb /etc/srsran/enb.conf --log.all_level debug --log.filename /logs/srsenb-'"$(date '+%Y-%m-%d_%H:%M:%S').log"
EPC_OPTS='--mme.encryption_algo EEA0 --mme.integrity_algo EIA1 --mme.mcc 999 --mme.mnc 70'
ENB_OPTS='--rf.device_name bladerf --enb.mcc 999 --enb.mnc 70 --expert.eea_pref_list EEA0'
IPRULE='iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE'

USAGE="
Usage:                    srsran.sh [METHOD] <OPTIONS>

Method Options:
  srsepc                  Start srsEPC container
  srsenb                  Start srsENB container
  net-access              Activate INET access for srsEPC
  down                    Terminate srsRAN virtual environment

Options:
  help                    List METHOD help options
  default                 List tool default options
"


cd ${WORKDIR}

netaccess() {
    if ! docker network list | grep -qs ${DRIVER}${VLANID}; then
        docker network create -d ${DRIVER} --subnet ${SUBNET} -o parent=${PARENT}.${VLANID} ${DRIVER}${VLANID}
    fi
}

checkepc() {
    if ! docker ps | grep -qs virt-srsepc; then
        echo "[ERR] srsEPC is required prior to executing ${1}"
        echo "${USAGE}"
        exit 1
    fi
}

case $1 in 
    "srsepc")
        case $2 in
            "help")
                docker run --rm -it virt-srsran srsepc --help
            ;;

            "default")
                echo "${EPC_CMD} ${EPC_OPTS}"
            ;;

            "")
                netaccess
                echo "[+] Executing: ${EPC_CMD} ${EPC_OPTS}"
                docker-compose run -d --name virt-srsepc srsepc ${EPC_CMD} ${EPC_OPTS}
            ;;

            *)
                netaccess
                echo "[+] Executing: ${EPC_CMD} ${2}"
                docker-compose run -d --name virt-srsepc srsepc ${EPC_CMD} ${2}
            ;;
        esac ;;

    "srsenb")
        case $2 in
            "help")
                docker run --rm -it virt-srsran srsenb --help
            ;;

            "default")
                echo "${ENB_CMD} ${ENB_OPTS}"
            ;;

            "")
                checkepc
                netaccess
                echo "[+] Executing: ${ENB_CMD} ${ENB_OPTS}"
                docker-compose run -d --name virt-srsenb srsenb ${ENB_CMD} ${ENB_OPTS}
            ;;

            *)
                checkepc
                netaccess
                echo "[+] Executing: ${ENB_CMD} ${2}"
                docker-compose run -d --name virt-srsenb srsenb ${ENB_CMD} ${2}
            ;;
        esac ;;

    "inet")
        checkepc

        echo "[*] Activating Internet access for srsEPC"
        docker exec virt-srsepc ${IPRULE}
        ;;

    "down")
        echo "[*] Shutting down environment"
        docker-compose down
        docker network rm ${DRIVER}${VLANID}

        echo "[*] Performing log rotation"
        file="srsRAN-$(date '+%Y-%m-%d_%H:%M:%S').tgz"
        
        tar -czf ./logs/${file} tmp-logs/*
        rm -rf ./tmp-logs/*
        echo "[+] Compressed logs: ./logs/${file}"
        ;;

    *)
        echo "${USAGE}"
        exit 1
 
    ;;

esac
