#!/usr/bin/env bash

set -a #export declared variables

. ${SHFLAGHS:-/usr/local/include/shflags}

DEFINE_string configfile '.bpkg.yml' "bpkg repository configuration file" c

FLAGS "$@" || (echo "Failed parsing options." >&2; exit $?)
eval set -- "${FLAGS_ARGV}"

if ! test -f "${FLAGS_configfile}"; then
    echo "config file ${FLAGS_configfile} not found"
    exit 127
fi
REALCONFIG="/tmp/${FLAGS_configfile}.yaml"
envsubst < "${FLAGS_configfile}" > "${REALCONFIG}"

SYNCS=$(cat ${REALCONFIG}  |yq -j e '.bpkg' -|jq -c '')

[[ -z "$DEBUG" ]] || set -x
for row in $(echo "${SYNCS}" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${row} | base64 --decode | jq -r "${1}"
    }

   INSTALL_PATH=$(_jq '.installPath // empty')
   PACKAGE=$(_jq '.package // empty')
   TOKEN=$(_jq '.token // empty')
   PACKAGEJSON=$(_jq '.package_json // empty')

   ([ -z "${INSTALL_PATH}" ] || [ -z "${PACKAGE}" ] ) && { (echo "required values: installPath,package"); exit 0; }

   rm -rf "${INSTALL_PATH:?}/$(basename ${PACKAGE}|sed  's/\:.*//g')"
   go-bpkg install --installPath "${INSTALL_PATH}" --package "${PACKAGE}" --token "${TOKEN}" --metadataJson "${PACKAGEJSON}"
done
