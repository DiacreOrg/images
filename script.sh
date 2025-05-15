#!/bin/bash

# Start podman
systemctl --user start podman.socket
systemctl --user enable podman.socket
loginctl enable-linger ${USER}
# Verifier qu'il est là
ls -la $XDG_RUNTIME_DIR/podman/podman.sock
# Cf. https://docs.podman.io/en/latest/markdown/podman-system-service.1.html

alias genpasswd='LC_ALL=C tr -dc '\''[:graph:]'\'' </dev/urandom | head -c 20; echo'

# Envirronnement
export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export BROWN_ORANGE='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export LIGHT_GRAY='\033[0;37m'
export DARK_GRAY='\033[1;30m'
export LIGHT_RED='\033[1;31m'
export LIGHT_GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export LIGHT_BLUE='\033[1;34m'
export LIGHT_PURPLE='\033[1;35m'
export LIGHT_CYAN='\033[1;36m'
export WHITE='\033[1;37m'

export NOCOLOR='\033[0m'
export PODNAME=csspod
export NETWORKNAME=cssnetwork
export MARIADB_ROOT_PASSWORD='HelloWorld!'
export MARIADB_USER=ogpuser
export MARIADB_PASSWORD='HelloWorld!'
export MARIADB_DATABASE=ogpdb
export OGP_SQL_HOST=mariadb
export OGP_SQL_USER=${MARIADB_USER}
export OGP_SQL_PASSWORD=${MARIADB_PASSWORD}
export OGP_SQL_DATABASE=${MARIADB_DATABASE}

# Creation des secrets
printf ${MARIADB_ROOT_PASSWORD} | podman secret create --replace scmariadbrootpassword -
printf ${MARIADB_USER} | podman secret create --replace scmariadbuser -
printf ${MARIADB_PASSWORD} | podman secret create --replace scmariadbpassword -
printf ${MARIADB_DATABASE} | podman secret create --replace scmariadbdatabase -
printf ${OGP_SQL_HOST} | podman secret create --replace scogpsqlhost -
printf ${OGP_SQL_USER} | podman secret create --replace scogpsqluser -
printf ${OGP_SQL_PASSWORD} | podman secret create --replace scogpsqlpassword -
printf ${OGP_SQL_DATABASE} | podman secret create --replace scogpsqldatabase -
podman secret inspect scmariadbrootpassword --showsecret | jq '.[].SecretData'

# Creation du reseau
podman network create ${NETWORKNAME}

# Creation des volumes
podman volume create --ignore database
podman volume create --ignore ogpdir
podman volume create --ignore backup

# Creation du POD
podman pod create --replace --name ${PODNAME} \
    --network ${NETWORKNAME} \
    --publish 3306:3306 \
    --publish 8080:8080 \
    --publish 8081:80 \
    --publish 12679:12679 \
    --publish 2100:21

# Creation des instances
podman run --detach --replace --name mariadb \
    --hostname mariadb \
    --network ${NETWORKNAME} \
    --volume database:/var/lib/mysql:Z \
    --publish 3306:3306 \
    --secret scmariadbrootpassword,type=env,target=MARIADB_ROOT_PASSWORD \
    --secret scmariadbuser,type=env,target=MARIADB_USER \
    --secret scmariadbpassword,type=env,target=MARIADB_PASSWORD \
    --secret scmariadbdatabase,type=env,target=MARIADB_DATABASE \
    --secret scogpsqlhost,type=env,target=OGP_SQL_HOST \
    --secret scogpsqluser,type=env,target=OGP_SQL_USER \
    --secret scogpsqlpassword,type=env,target=OGP_SQL_PASSWORD \
    --secret scogpsqldatabase,type=env,target=OGP_SQL_DATABASE \
    docker.io/library/mariadb:11.7.2
podman run --detach --replace --name adminer \
    --hostname adminer \
    --network ${NETWORKNAME} \
    --publish 8080:8080 \
    --env ADMINER_DEFAULT_SERVER=mariadb \
    docker.io/library/adminer:5.2.1
podman run --detach --replace --name ogp-panel \
    --hostname ogp-panel \
    --network ${NETWORKNAME} \
    --publish 8081:80 \
    --secret scmariadbrootpassword,type=env,target=MARIADB_ROOT_PASSWORD \
    --secret scmariadbuser,type=env,target=MARIADB_USER \
    --secret scmariadbpassword,type=env,target=MARIADB_PASSWORD \
    --secret scmariadbdatabase,type=env,target=MARIADB_DATABASE \
    --secret scogpsqlhost,type=env,target=OGP_SQL_HOST \
    --secret scogpsqluser,type=env,target=OGP_SQL_USER \
    --secret scogpsqlpassword,type=env,target=OGP_SQL_PASSWORD \
    --secret scogpsqldatabase,type=env,target=OGP_SQL_DATABASE \
    diacreorg/ogp-panel:latest
podman run --detach --replace --name ogp-agent \
    --hostname ogp-agent \
    --publish 12679:12679 \
    --publish 2100:21 \
    --network ${NETWORKNAME} \
    --volume ogpdir:/home/ogp_agent/OGP_User_Files:Z \
    --secret scmariadbrootpassword,type=env,target=MARIADB_ROOT_PASSWORD \
    --secret scmariadbuser,type=env,target=MARIADB_USER \
    --secret scmariadbpassword,type=env,target=MARIADB_PASSWORD \
    --secret scmariadbdatabase,type=env,target=MARIADB_DATABASE \
    --secret scogpsqlhost,type=env,target=OGP_SQL_HOST \
    --secret scogpsqluser,type=env,target=OGP_SQL_USER \
    --secret scogpsqlpassword,type=env,target=OGP_SQL_PASSWORD \
    --secret scogpsqldatabase,type=env,target=OGP_SQL_DATABASE \
    diacreorg/ogp-agent:latest

# Affichage de la configuration
echo -e "${GREEN}"'Login into bash with psql :'"${NOCOLOR}"
echo -e "${GREEN}"   'podman exec -it mariadb mariadb --user=root --password="$(podman secret inspect scmariadbrootpassword --showsecret | jq -r '.[].SecretData')"'"${NOCOLOR}"
echo -e "${YELLOW}"'Login browser for adminer :'"${NOCOLOR}"
echo -e "${YELLOW}"'  - url      : http://localhost:8080'"${NOCOLOR}"
echo -e "${YELLOW}"'  - login    :' "root""${NOCOLOR}"
echo -e "${YELLOW}"'  - password :' "$(podman secret inspect scmariadbrootpassword --showsecret | jq '.[].SecretData')""${NOCOLOR}"
echo -e "${PURPLE}"'Login browser for ogp-panel(web) :'"${NOCOLOR}"
echo -e "${PURPLE}"'  - url      : http://localhost:8081'"${NOCOLOR}"
echo -e "${PURPLE}"'  - login    :' "agpadmin""${NOCOLOR}"
echo -e "${PURPLE}"'  - password :' "$(podman secret inspect scmariadbrootpassword --showsecret | jq '.[].SecretData')""${NOCOLOR}"
echo -e "${CYAN}"'Login ogp-agent :'"${NOCOLOR}"
echo -e "${CYAN}"'  - url      : tcp://localhost:12679'"${NOCOLOR}"
echo -e "${CYAN}  - "$(podman logs ogp-agent)"${NOCOLOR}"
