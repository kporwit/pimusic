FROM arm32v5/debian

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y wget unzip python3 python3-pip sqlite3
RUN pip3 install CherryPy

RUN useradd -ms /bin/bash cherrymusic
USER cherrymusic
WORKDIR /home/cherrymusic/
RUN wget https://github.com/devsnd/cherrymusic/archive/refs/heads/devel.zip
RUN unzip devel.zip && rm devel.zip
RUN mkdir ${HOME}/.config; mkdir ${HOME}/music
#RUN ls "${HOME}/cherrymusic-devel/"
#COPY cherrymusic.conf ${HOME}/.config/cherrymusic.conf
EXPOSE 8181
WORKDIR /home/cherrymusic/cherrymusic-devel/
ENTRYPOINT python3 cherrymusic --setup --port 8181
#ToDo install ImageMick etc
