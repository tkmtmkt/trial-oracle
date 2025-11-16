#!/usr/bin/env bash
SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
BASE_DIR=$(cd ${SCRIPT_DIR}/..;pwd)

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
#set -o verbose

mkdir -p ${BASE_DIR}/db/opt/oracle/oradata/
chmod a+w ${BASE_DIR}/db/opt/oracle/oradata/
docker compose up -d
