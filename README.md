# pimusic
Docker container with [cherrymusic](https://github.com/devsnd/cherrymusic) for ARM (armv[5-7]) and AMD64 (x86_64) architecture processor. It works out of the box in the raspberry pi 2B. Docker image is published on DockerHub at [kporwit/pimusic](https://hub.docker.com/repository/docker/kporwit/pimusic) for ARM architecture and [kporwit/pimusic_amd64](https://hub.docker.com/repository/kporwit/pimusic_amd64) for AMD64 architecture.

# Prerequisites
 1. docker - check [this page](https://docs.docker.com/engine/install/) for installation and setup instructions.
 2. wget or git.

# Quickstart:

1. Download `wget https://github.com/kporwit/pimusic/archive/refs/heads/master.zip` or clone the repository `git clone https://github.com/kporwit/pimusic.git`.
2. If necessary unzip the downloaded zip file `unzip https://github.com/kporwit/pimusic/archive/refs/heads/master.zip` and enter pimusic path `cd ./pimusic`.
3. Run `./run_pimusic.sh -P /path/to/Your/music/`.
4. Check website `<Your pi IP address or localhost>:8181` for Your own cherrymusic server!.


# Usage: 

To run the container You can either build the container from provided Dockerfile and run it manually or run run_pimusic.sh script which will set up everything for You.

```
./run_pimusic.sh
-P <path to Your music> The path which contains Your music. It will be mapped to internal pimusic folder.
-p <publish port> Port where the cherrymusic will be published (e.g pi-IP:8181). Default is set up to 8181.
-V <pimusic version> Version of pimusic to run (e.g. v0.0.1). Default is set up to latest.
-h displays help.
```

Only `-P` is mandatory as it connects Your music folder with internal pimusic path: `/home/pimusic/music`.
If You want to install development version You need to pass `-V` flag with `develop` value.

The script creates two volumes to keep the data between the container restart:
* pimusic_config_vol - volume which keeps the cherrymusic.conf after first setup.
* pimusic_share_vol - volume which keeps all information about created users/playlists/configuration.

# How to enable HTTPS support:

Unfortunately, as we want to keep the SSL certificate and private key of the certificate as secure as possible but also give access to the pimusic user in the container You need to do couple of manual actions:

1. Add new group (substitute `<group name>` with name that You want) with GID 8181 on the host machine (pimusic container user is in the group with that GID): `sudo addgroup --gid 8181 <group name>`.
2. Change group ownership of the SSL certificate file and private key of the certificate to the group created in step 1: `sudo chgrp <group name> <certificate file> && sudo chgrp <group name> <private key>`.
3. Make sure that that SSL certificate and private key are both readable by the group e.g: `chmod 740 <certificate file> <private key>`.

After performing the commands presented above the group `<group name>` will be created. The pimusic user in the container belongs to the group with GID 8181, thus it will have access to the files. 
You can run `run_pimusic.sh` script now with `-S` flag which enables SSL encryption on the container side with `-c` flag which points to Your `<certificate file>` and `-k` flag which points to certificate `<private key`.

```
./run_pimusic.sh
-P <path to Your music> The path which contains Your music. It will be mapped to internal pimusic folder.
-p <publish port> Port where the cherrymusic will be published (e.g pi-IP:8181). Default is set up to 8181.
-V <pimusic version> Version of pimusic to run (e.g. v0.0.1). Default is set up to latest.
-h displays help.
-S Enables SSL encryption (all flags below are valid only when this one is enabled).
-s <SSL port> Port for SSL connection. Default is set up to 8443.
-c <path to SSL certificate> Path to the certificate of Your domain.
-k <path to private key of the SSL certificate> Path to the private key of the certificate.
```

## w/o start script:

The config file is created in `/home/pimusic/.config/cherrymusic/` so it would be good to add a volume for that as we want to keep a dummy file there to restrain the pimusic for running once for setup and exit. All needed config parameters are passed in the entrypoint of the dockerfile and cherrymusic reads the parameters from there.
Similarly, volume for `/home/pimusic/.local/share/cherrymusic/` will keep the users/playlists/configuration data.
The `PUBLISH_PORT` environment variable needs to be filled with port number where the pimusic will be published.
The same port needs to be exposed to the world as we need to access cherrymusic from the outside of the container.
If You want to use pimusic with HTTPS support You need to set up environment variable `SSL_ENABLED` to True. 
Moreover, the `SSL_PORT` environment variable needs to be filled with the port You want to use (8443 by default). All connections to the `PUBLISH_PORT` will be redirected here. 
You also need to connect the certificate and private key with the container paths:

* `/home/pimusic/certs/server.crt` - for certificate
* `/home/pimusic/certs/server.key` - for private key

via volumes. 
The read permission for others need to be set up for Your certificate and the key. This is necessary as pimusic user need to read them. The last point to make HTTPS support is to expose the `SSL_PORT` to the world.

# Troubleshooting:

In case of any trouble it is always worth to check the logs via command `docker logs pimusic`. Known problems and solutions are presented below.

### Process id file `/home/pimusic/.local/share/cherrymusic/cherrymusic.pid already exists`.

If the pimusic container crashed for some reason (power outage, etc.) the cherrymusic application could not perform clean exit.
The `cherrymusic.pid` lockfile could not be deleted in such case.
To solve this problem and start pimusic container normally You need to remove `cherrymusic.pid` from the volume `pimusic_share_vol`. 
Docker volumes are usually located at `/var/lib/docker/volumes` and in this case You need to run command: `sudo rm -v /var/lib/docker/volumes/pimusic_share_vol/_data/share/cherrymusic/cherrymusic.pid` which will solve the problem of existing lockfile.

# ToDo

- [x] Add Imagemagick
- [x] HTTPS support
- [x] Add optional dependencies: live transcoding, python-unidecode, python-gobject
- [ ] Try to make the image thinner

For full scope of the tasks look for the pimusic project in Projects.
