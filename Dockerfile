#Download and compile imagemagick from source
FROM arm32v5/debian AS imagemagick_builder
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y wget tar build-essential
RUN wget https://download.imagemagick.org/ImageMagick/download/ImageMagick.tar.gz
RUN tar xzfv ImageMagick.tar.gz
RUN mkdir imagemagick
WORKDIR ImageMagick-7.1.0-4
RUN ./configure --prefix=/root/imagemagick
RUN make
RUN ls /root/
RUN ls /root/imagemagick/

FROM arm32v5/debian

ENV PUBLISH_PORT=8181
ARG PIUSER=pimusic
ARG PIHOMEDIR=/home/${PIUSER}

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y wget unzip python3 python3-pip sqlite3
RUN pip3 install CherryPy
COPY --from=imagemagick_builder /root/imagemagick /root/imagemagick
RUN ls /root/imagemagick/

RUN useradd -ms /bin/bash ${PIUSER}
USER ${PIUSER}
WORKDIR ${PIHOMEDIR}
RUN wget https://github.com/devsnd/cherrymusic/archive/refs/heads/devel.zip
RUN unzip devel.zip && rm devel.zip
RUN mkdir -p music; mkdir -p .local; mkdir -p .config

WORKDIR ${PIHOMEDIR}/cherrymusic-devel/
ENTRYPOINT python3 cherrymusic --conf \
  media.basedir=/home/pimusic/music \
  server.port=${PUBLISH_PORT} \
  server.localhost_only=False \
  server.permit_remote_admin_login=True
