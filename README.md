# pimusic
The container for [cherrymusic](https://github.com/devsnd/cherrymusic) for rev 5 ARM architecture processor. It works out of the box in the raspberry pi 2B. Docker image is published in DockerHub at [kporwit/pimusic](https://hub.docker.com/repository/docker/kporwit/pimusic).

# Quickstart:

1. Download `wget https://github.com/kporwit/pimusic/archive/refs/heads/master.zip` or clone the repository `git clone https://github.com/kporwit/pimusic.git`.
2. If necesarry unzip the downloaded zip file `unzip https://github.com/kporwit/pimusic/archive/refs/heads/master.zip` and enter pimusic path `cd ./pimusic`.
3. Run `./run_pimusic.sh -P /path/to/Your/music/`.
4. Check website `piIP:8181` for pimusic initial setup.


# Usage: 

To run the container You can either build the container from provided Dockerfile and run it manually or run run_pimusic.sh script which will set up everything for You.

```
./run_pimusic.sh
-P <path to Your music> The path which contains Your music. It will be mapped to internal pimusic folder.
-p <publish port> Port where the cherrymusic will be published (e.g piIP:8181). Default is set up to 8181.
-V <pimusic version> Version of pimusic to run (e.g. v0.0.1). Default is set up to latest.
-h displays help.
-S Enables SSL encryption (all flags below are valid only when this one is enabled).
-s <SSL port> Port for SSL connection.
-c <path to SSL certificate> Path to the certificate of Your domain.
-k <path to private key of the SSL certificate> Path to the private key of the certificate.
```

Only -P is mandatory as it connects Your music folder with internal pimusic path: /home/pimusic/music.

The script creates two volumes to keep the data between the container restart:
* pimusic_config_vol - volume which keeps the cherrymusic.conf after first setup.
* pimusic_share_vol - volume which keeps all information about created users/playlists/configuration.

## w/o start script:

The config file is created in /home/pimusic/.config/cherrymusic/ so it would be good to add a volume for that as we want to keep a dummy file there to restrain the pimusic for running once for setup and exit. All needed config paramaters are passed in the entrypoint of the dockerfile and cherrymusic reads the parameters from there.
Similarly, volume for /home/pimusic/.local/share/cherrymusic/ will keep the users/playlists/configuration data.
The `PUBLISH_PORT` environment variable needs to be filled with port number where the pimusic will be published.
The same port needs to be exposed to the world as we need to access cherrymusic from the outside of the container.
If You want to use pimusic with HTTPS support You need to set up environment variable `SSL_ENABLED` to True. 
Moreover, the `SSL_PORT` environment variable needs to be filled with the port You want to use (8443 by default). All connections to the `PUBLISH_PORT` will be redirected here. 
You also need to connect the certificate and private key with the container paths:
* /home/pimusic/certs/server.crt - for certificate
* /home/pimusic/certs/server.key - for private key
via volumes. 
The read permission for others need to be set up for Your certificate and the key. This is necessary as pimusic user need to read them. The last point to make HTTPS support is to expose the `SSL_PORT` to the world.

# ToDo
- [x] Add Imagemick
- [x] HTTPS support
- [ ] Try to make the image thinner
