#!/bin/bash
set -e
#TODO: Support python virtual environments for now global

COLOR_END='\e[0m'
COLOR_RED='\e[0;31m'

# This current directory.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(cd "$DIR/../../" && pwd)
EXTERNAL_ROLE_DIR="$ROOT_DIR/roles/external"
ROLES_REQUIREMNTS_FILE="$ROOT_DIR/roles/dependencies.yml"

# Exit msg
msg_exit() {
    printf "$COLOR_RED$@$COLOR_END"
    printf "\n"
    printf "Saliendo...\n"
    exit 1
}

# Trap if ansible-galaxy failed and warn user
cleanup() {
    msg_exit "Error en la actualización. No publicar los roles hasta haber corregido el problema."
}
trap "cleanup"  ERR INT TERM

# Check ansible-galaxy
[[ -z "$(which ansible-galaxy)" ]] && msg_exit "ansible-galaxy no esta disponible en tu path."

# Check roles req file
[[ ! -f "$ROLES_REQUIREMNTS_FILE" ]]  && msg_exit "roles_requirements '$ROLES_REQUIREMNTS_FILE' no existe o hay un problema de permisos.\nPor favor, revísalo y ejecutalo de nuevo."

# Remove existing roles
if [ -d "$EXTERNAL_ROLE_DIR" ]; then
    cd "$EXTERNAL_ROLE_DIR"
	if [ "$(pwd)" == "$EXTERNAL_ROLE_DIR" ];then
	  echo "Eliminando roles actuales en '$EXTERNAL_ROLE_DIR/*'"
	  rm -rf *
	else
	  msg_exit "Error en el path no se puede cambiar al directorio $EXTERNAL_ROLE_DIR"
	fi
fi



# Install roles
ansible-galaxy install -r "$ROLES_REQUIREMNTS_FILE" --force --no-deps -p "$EXTERNAL_ROLE_DIR"

exit 0
