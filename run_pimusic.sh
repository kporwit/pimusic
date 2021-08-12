#!/bin/bash
#===============================================================================
#
#          FILE:  run_pimusic.sh
# 
#         USAGE:  ./run_pimusic.sh -P <path to Your music>
# 
#   DESCRIPTION:  This script runs the pimusic container with all proper variables set.
# 
#       OPTIONS: -P <path to Your music> The path which contains Your music. It will be mapped to internal pimusic folder.
#                -p <publish port> Port where the cherrymusic will be published (e.g <pi IP>:8181). Default is set up to 8181.
#                -V <pimusic version> Version of pimusic to run (e.g. v0.0.2). Default is set up to latest.
#                -h displays help.
#        AUTHOR:  Kamil Porwit (), kamilporwit93@gmail.com
#       VERSION:  1.0
#       CREATED:  08/09/2021 09:02:58 AM CEST
#===============================================================================

path_to_music=''
version='latest'
publish_port='8181'

print_usage() {
  printf "Usage:\n ./run_pimusic.sh -P <The path which contains Your music> -p <Port where the cherrymusic will be published (e.g 8181)> -V <Version of pimusic to run (e.g. v0.0.2)>\n"
}

while getopts 'P:p:V:h' flag; do
  case "${flag}" in
    P) path_to_music=${OPTARG};;
    p) publish_port=${OPTARG};;
    V) version=${OPTARG} ;;
    h) print_usage 
       exit 1 ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ -z "${path_to_music}" ]; then
  printf "ERROR: music path was not given. It must be passed as an -P flag (e.g: -P </path/to/your/music>).\n"
  exit 21
fi


if [[ ! (-e "${path_to_music}" || -d "${path_to_music}" || -r "${path_to_music}") ]]; then
  printf "ERROR: music path: %s either does not exists, is not a directory or is not readable by %s user.\n" "${path_to_music}" "${USER}"
  exit 22
fi

if ! echo "${publish_port}" | grep -E "[0-9]{4,}" > /dev/null; then
  printf "ERROR: Passed port is not in proper format: <%s>. It should contain at least four numeric characters.\n" "${publish_port}"
  exit 2
fi

printf "Starting up pimusic container (version: %s) on port %s with music path %s\n" "${version}" "${publish_port}" "${path_to_music}"
docker run -d --name pimusic \
  -e PUBLISH_PORT="${publish_port}" -p "${publish_port}:${publish_port}" \
  -v "${path_to_music}:/home/pimusic/music" \
  --restart=unless-stopped \
  --mount source=pimusic_share_vol,target=/home/pimusic/.local \
  --mount source=pimusic_config_vol,target=/home/pimusic/.config \
  "pimusic:${version}"
