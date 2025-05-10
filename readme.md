# OGP MariaDB Adminer

~~~bash
export MARIADB_ROOT_PASSWORD='HelloWorld!'
export MARIADB_PODNAME=maria
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

printf ${MARIADB_ROOT_PASSWORD} | podman secret create --replace dbpassword -
podman secret inspect dbpassword --showsecret | jq '.[].SecretData'

podman volume create database
podman pod create --name ${MARIADB_PODNAME} --publish 3306:3306 --publish 8080:8080
podman run --detach --replace --name mariadb \
    --pod=${MARIADB_PODNAME} \
    --volume database:/var/lib/mysql:Z \
    --secret dbpassword,type=env,target=MARIADB_ROOT_PASSWORD \
    docker.io/library/mariadb:11.7.2
podman run --detach --replace --name adminer \
    --pod=${MARIADB_PODNAME} \
    --env ADMINER_DEFAULT_SERVER=mariadb \
    docker.io/library/adminer:5.2.1


# Contenu de la base de donnée
ls -la $(podman volume inspect database | jq '.[].Mountpoint' | tr -d '"')
echo $(podman volume inspect database | jq '.[].Mountpoint' | tr -d '"')

# Affichage de la configuration
echo -e "${GREEN}"'Login into bash with psql :'"${NOCOLOR}"
echo -e "${GREEN}"'Login browser :'"${NOCOLOR}"
echo -e "${GREEN}"'  - url      : http://localhost:8080'"${NOCOLOR}"
echo -e "${GREEN}"'  - login    :' "root""${NOCOLOR}"
echo -e "${GREEN}"'  - password :' "$(podman secret inspect dbpassword --showsecret | jq '.[].SecretData')""${NOCOLOR}"

# Backup
podman volume create backup
podman run --pod=${MARIADB_PODNAME} --volume backup:/backup --rm mariadb:11.7.2 mariadb-backup --help

# Pour migrer vers kubernetes
podman generate kube ${MARIADB_PODNAME}

# Pour tout supprimer
podman pod stop --ignore ${MARIADB_PODNAME}
podman pod rm --ignore --force ${MARIADB_PODNAME}
podman volume rm database
podman system prune --all --force
~~~

Pour tester

~~~bash
podman pull debian:11.11
podman run --rm --replace --interactive --tty --cap-add=NET_RAW --name debian docker.io/library/debian:11.11 /bin/bash
~~~
