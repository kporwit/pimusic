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
#                -S Enables SSL encryption (all flags below are valid only when this one is enabled).
#                -s <SSL port> Port for SSL connection.
#                -c <path to SSL certificate> Path to the certificate of Your domain.
#                -k <path to private key of the SSL certificate> Path to the private key of the certificate.
#        AUTHOR:  Kamil Porwit (), kamilporwit93@gmail.com
#       VERSION:  2.0
#       CREATED:  08/09/2021 09:02:58 AM CEST
#===============================================================================

path_to_music=''
version='latest'
publish_port='8181'
ssl_port='8443'
ssl_enabled='False'
path_to_certificate=''
path_to_private_key=''
access_group_gid='8181'

print_usage() {
  printf "Usage:\n ./run_pimusic.sh -P <The path which contains Your music> -p <Port where the cherrymusic will be published (e.g 8181)> -V <Version of pimusic to run (e.g. v0.0.2)>\n\t -S <enables SSL encryption> -s <Port for the SSL encryption> -c <Path to the SSL certyficate> -k <Path to the private key of the certificate>\n"
}

readable_by_group() {
  local passed_file="$1"
  if [ -L "$passed_file" ]; then
    printf "WARNING: the file %s is a symbolic link. Please make sure that the original file belongs to the group with %s GID and has read permission for that group.\n" "$passed_file" "$access_group_gid"
  elif [ "$(stat --print=%g $passed_file)" != "$access_group_gid" ]; then
    printf "ERROR: %s does is not own by the group with GID %s.\n" "$passed_file" "$access_group_gid"
    return 1
  fi
  permissions=$(stat --print=%A $passed_file)
  ro_byte=$(echo $permissions | cut -c 5)
  if [ "$ro_byte" = "r" ]; then
    return 0
  else
    return 1
  fi
}

while getopts 'P:p:V:Ss:c:k:h' flag; do
  case "${flag}" in
    P) path_to_music=${OPTARG};;
    p) publish_port=${OPTARG};;
    S) ssl_enabled='True' ;;
    s) ssl_port=${OPTARG} ;;
    c) path_to_certificate=${OPTARG} ;;
    k) path_to_private_key=${OPTARG} ;;
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
  exit 23
fi

if [ "$ssl_enabled" = "True" ]; then

  if ! readable_by_group "${path_to_certificate}"; then
    printf "ERROR: certificate file is not readable by group with %s GID.\n" "$access_group_gid"
    exit 31
  fi

  if [[ ! (-e "${path_to_certificate}" || -L "${path_to_certificate}") ]]; then
    printf "ERROR: certificate path: %s does not exists.\n" "${path_to_certificate}"
    exit 31
  fi

  if ! readable_by_group "${path_to_private_key}"; then
    printf "ERROR: private key file is not readable by group with %s GID.\n" "$access_group_gid"
    exit 31
  fi
  
  if [[ ! (-e "${path_to_private_key}" || -L "${path_to_certificate}") ]]; then
    printf "ERROR: private key path: %s does not exists.\n" "${path_to_private_key}"
    exit 32
  fi
  
  if ! echo "${ssl_port}" | grep -E "[0-9]{4,}" > /dev/null; then
    printf "ERROR: Passed port is not in proper format: <%s>. It should contain at least four numeric characters.\n" "${ssl_port}"
    exit 33
  fi

fi

if [ "$ssl_enabled" = "False" ]; then
  printf "Starting up pimusic container (version: %s) on port %s with music path %s\n" "${version}" "${publish_port}" "${path_to_music}"
  docker run -d --name pimusic \
    -p "${publish_port}:${publish_port}" \
    -e PUBLISH_PORT="${publish_port}" \
    -v "${path_to_music}:/home/pimusic/music" \
    --restart=unless-stopped \
    --mount source=pimusic_share_vol,target=/home/pimusic/.local \
    --mount source=pimusic_config_vol,target=/home/pimusic/.config \
    "kporwit/pimusic:${version}"
else
  printf "Starting up pimusic container with SSL support (version: %s) on port %s (SSL port %s) with music path %s\n" "${version}" "${publish_port}" "${ssl_port}" "${path_to_music}"
  docker run -d --name pimusic \
    -p "${publish_port}:${publish_port}" \
    -e PUBLISH_PORT="${publish_port}" \
    -p "${ssl_port}:${ssl_port}" \
    -e SSL_ENABLED="True" \
    -e SSL_PORT="${ssl_port}" \
    -v "${path_to_certificate}:/home/pimusic/certs/server.crt" \
    -v "${path_to_private_key}:/home/pimusic/certs/server.key" \
    -v "${path_to_music}:/home/pimusic/music" \
    --restart=unless-stopped \
    --mount source=pimusic_share_vol,target=/home/pimusic/.local \
    --mount source=pimusic_config_vol,target=/home/pimusic/.config \
    "kporwit/pimusic:${version}"
fi
