#!/bin/bash

# TrueNAS calls this script twice in the following manner:
# `script set domain validation_name validaton_context timeout`
# `script unset domain validation_name validation_contex`

LOCAL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

LOGFILE="${LOCAL_DIR}/.logs/$(date "+%Y%m%d-%H%M%S").log"
if [ ! -f "${LOGFILE}" ]; then
  mkdir -p "${LOCAL_DIR}/.logs"
  touch "${LOGFILE}"
  chmod 600 "${LOGFILE}"
fi
_tn_log() {
  echo $(date "+[%a %b %d %r %Z %Y]")" $1" | tee --append "${LOGFILE}"
}

_tn_log "Validating acme.sh"
ACMESH_SCRIPT="${LOCAL_DIR}/acmesh/acme.sh"
if [ -f "${ACMESH_SCRIPT}" ]; then
  source "${ACMESH_SCRIPT}" >/dev/null 2>&1
else
  _tn_log "Invalid acme.sh script, try running 'git submodule update --init'"
  exit 1
fi

_tn_log "Validating settings"
export $(grep -v '^#' settings.local | xargs -d '\n')
DNSAPI_SCRIPT="${LOCAL_DIR}/acmesh/dnsapi/${TRUENAS_DNSPROVIDER}.sh"
if [ -f "${DNSAPI_SCRIPT}" ]; then
  source "${DNSAPI_SCRIPT}"
else
  _tn_log "Invalid TRUENAS_DNSPROVIDER '${TRUENAS_DNSPROVIDER}'"
  exit 1
fi

_tn_log "Calling '${TRUENAS_DNSPROVIDER}' dnsapi from acme.sh"
if [ "${1}" == "set" ]; then
  ${TRUENAS_DNSPROVIDER}_add "${3}" "${4}" 2>&1 | tee --append "${LOGFILE}"
elif [ "${1}" == "unset" ]; then
  ${TRUENAS_DNSPROVIDER}_rm "${3}" "${4}" 2>&1 | tee --append "${LOGFILE}"
else
  _tn_log "Invalid argument"
fi
