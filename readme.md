# OGP MariaDB Adminer

~~~bash
podman exec ogp-panel env
podman exec ogp-agent ls -la /home/ogp_agent/OGP_User_Files
podman exec -it ogp-agent bash

# Contenu de la base de donnée
ls -la $(podman volume inspect database | jq '.[].Mountpoint' | tr -d '"')
echo $(podman volume inspect database | jq '.[].Mountpoint' | tr -d '"')

# mariadb cli
podman exec -it mariadb mariadb --user=root --password="$(podman secret inspect scmariadbrootpassword --showsecret | jq -r '.[].SecretData')"

# Backup
podman run --volume backup:/backup --rm mariadb:11.7.2 mariadb-backup --help

# Pour migrer vers kubernetes
podman generate kube ${PODNAME}

# Pour tout supprimer
podman pod stop --ignore ${PODNAME}
podman pod rm --ignore --force ${PODNAME}
podman volume rm database
podman system prune --all --force
~~~

## Pour tester

~~~bash
# podman pull debian:11.11
podman run --rm --replace --interactive --tty --cap-add=NET_RAW --name debian docker.io/library/debian:11.11 /bin/bash
~~~


## Sources

- [https://github.com/henri9813/docker-opengamepanel](https://github.com/henri9813/docker-opengamepanel)
- [https://opengamepanel.org/install_guide/panel.html](https://opengamepanel.org/install_guide/panel.html)
