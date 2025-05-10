# OGP-Panel

Todo

~~~bash
podman build --log-level=debug -t ogp-panel:latest .
podman run --rm --replace --cap-add=NET_RAW --name ogp-panel
podman run --rm --replace --interactive --tty --cap-add=NET_RAW --name ogp-panel --publish 8080:80 ogp-panel:latest /bin/bash
~~~
