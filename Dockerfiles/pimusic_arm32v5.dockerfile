#Download and compile imagemagick from source
FROM arm32v5/debian AS imagemagick_builder
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget tar build-essential
RUN wget https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-7.1.0-8.tar.gz && \
    tar xzfv ImageMagick-7.1.0-8.tar.gz && \
    rm ImageMagick-7.1.0-8.tar.gz
RUN mkdir -p /root/imagemagick
WORKDIR ImageMagick-7.1.0-8
RUN ./configure --prefix=/root/imagemagick
RUN make
RUN make install
#Pimusic builder
FROM arm32v5/debian AS pimusic_builder
#Set up variables
ENV PUBLISH_PORT=8181
ENV SSL_ENABLED=False
ENV SSL_PORT=8443
ARG PIUSER=pimusic
ARG PIHOMEDIR=/home/${PIUSER}
#Uppgrade and install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget unzip python3 python3-pip sqlite3 flac
RUN pip3 install CherryPy Unidecode
#Add pimusic user and group, copy imagemagick and fix the links
RUN addgroup --gid 8181 pimusicgroup && useradd -ms /bin/bash -G pimusicgroup ${PIUSER}
COPY --from=imagemagick_builder /root/imagemagick ${PIHOMEDIR}/imagemagick
RUN ldconfig /home/pimusic/imagemagick/lib
#Work as a pimusic user, add imagemagick path to the PATH env variable
USER ${PIUSER}
WORKDIR ${PIHOMEDIR}
ENV PATH="$PATH:/home/pimusic/imagemagick/bin/"
#Download cherrymusic
RUN wget https://github.com/devsnd/cherrymusic/archive/refs/heads/devel.zip && \
    unzip devel.zip && \
    rm devel.zip
RUN mkdir -p music .local .config certs
#Start cherrymusic with given settings
WORKDIR ${PIHOMEDIR}/cherrymusic-devel/
#ENTRYPOINT ./cherrymusic --setup --port 8181
ENTRYPOINT ./cherrymusic --conf \
  media.basedir=/home/pimusic/music \
  server.port=${PUBLISH_PORT} \
  server.localhost_only=False \
  server.permit_remote_admin_login=True \
  server.ssl_enabled=$SSL_ENABLED \
  server.ssl_certificate=/home/pimusic/certs/server.crt \
  server.ssl_private_key=/home/pimusic/certs/server.key \
  server.ssl_port=$SSL_PORT
