#! /usr/bin/env bash

trap "exit" INT

source $(dirname "${BASH_SOURCE[0]}")/tg_token

M_HOST="${1:-YourYostname.com"
CHAT_ID='-00000000'
MSG="
	Host ${M_HOST} says :: 
	\${MESSAGE}
"

TG_REQUEST="curl https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${CHAT_ID} --form \"text=${MSG}\""

retry() {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** count))
    count=$((count + 1))
    if [[ ${count} -lt ${retries} ]]; then
      echo "Retry ${count}/{$retries} exited ${exit}, retrying in ${wait} seconds..."
      sleep ${wait}
    else
      echo "Retry ${count}/${retries} exited ${exit}, no more retries left."
      return ${exit}
    fi
  done
  return 0
}

ping_command() {
    ping -c 1 ${M_HOST} >/dev/null 2>&1
}

while true; do
	if [[ ! -f /tmp/ping.tmp ]]; then
		if retry 6 ping_command; then
			sleep 5
		else
			ALERT_MESSAGE=" - Something happened!"
			eval "${TG_REQUEST}"
			echo "$(date +'%F %T'): Host down!."
			touch /tmp/ping.tmp
		fi
	else
		if retry 6 ping_command; then
			rm /tmp/ping.tmp
			echo "$(date +'%F %T'): Host is UP!"
			ALERT_MESSAGE=" - Host is UP!"
			eval "${TG_REQUEST}"
		else
			echo "$(date +'%F %T'): Down. Retry in 60 seconds..."
			sleep 60
		fi
	fi
done

exit 0
