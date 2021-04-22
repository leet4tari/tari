#!/bin/bash
#
# Script to start tor
#
#TOR=$(which tor)
#$TOR --allow-missing-torrc --ignore-missing-torrc \
#  --clientonly 1 --socksport 9050 --controlport 127.0.0.1:9051 \
#  --log "notice stdout" --clientuseipv6 1

base_path="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
#base_path=${base_path:-$(dirname $0)}
config_path="${base_path}/config"
exe_path="${base_path}/runtime"

envFile=${envFile:-"$config_path/tari-env"}
if [ -f "$envFile" ]; then
  echo "Overriding Environment with $envFile file for settings ..."
  source "$envFile"
fi

# http://mywiki.wooledge.org/ProcessManagement
torSocksPort=${torSocksPort:-9050}
torControlPort=${torControlPort:-'127.0.0.1:9051'}

call_torLoaunch() {
  $torBin --allow-missing-torrc --ignore-missing-torrc \
    --clientonly 1 --socksport $torSocksPort --controlport ${torControlPort} \
    --log "notice stdout" --clientuseipv6 1 &
  export torPid=$!
  sleep 2
}

# Tor as a system service
if [ "${torConnection}" == "service" ]; then
  echo "Tor Service"
fi

# Tor as a subprocess of tari_base_node
if [ "${torConnection}" == "subprocess" ]; then
  torBin=$(which tor)
  if [ -e $torBin ]; then
    echo "Tor can't be found!"
    exit -1
  fi
  echo "Tor Subprocess starting ..."
  call_torLoaunch
  if kill -0 "${torPid}"; then
    echo "Tor subprocessed successfully - ${torPid}"
  else
    wait "${torPid}"; torExit=$?
    echo "Tor process disappeared. Something may have gone wrong."
    echo "Tor exit code was $torExit."
    exit -1
  fi
fi

# Default or Terminal
if [ "${torConnection}" == "terminal" ] || [ -z "${torConnection}" ]; then
  echo "Tor terminal"
  tor_running=$(lsof -nP -iTCP:$torSocksPort)
  if [ -z "${tor_running}" ]; then
    echo "Starting Tor"
    # Needs work - shard env for lunch
    #open -a Terminal.app "${exe_path}/start_tor.sh"
    #ping -c 15 localhost > /dev/null
    open -a Terminal.app call_torLoaunch
  fi
fi

# Tor running test
if [ "${torTest}" != "no" ] || [ -z "${torTest}" ]; then
  echo "Tor connectiong testing ..."
  #curl --socks5 localhost:$torSocksPort --socks5-hostname localhost:$torSocksPort -s https://check.torproject.org/ | cat | grep -m 1 Congratulations | xargs
  curl --socks5 localhost:$torSocksPort --socks5-hostname localhost:$torSocksPort -s https://check.torproject.org/ | cat | grep -qcm1 Congratulations
  if [ $? -eq 0 ]; then
    echo "Tor Running"
  else
    echo "Tor Not Running!"
    exit -1
  fi
# ToDo - Cuustom Env Tor Test
fi

echo "Done"