#!/bin/bash
#===============================================================================
#
#          FILE:  prepare_dockerfile.sh
# 
#         USAGE:  ./prepare_dockerfile.sh 
# 
#   DESCRIPTION:  Script for preparing Dockerfile with the values obtained from config.yaml
# 
#        AUTHOR:  Kamil Porwit (), kamilporwit93@gmail.com
#       VERSION:  1.0
#       CREATED:  09/29/21 08:42:03 CEST
#===============================================================================

print_usage() {
  printf "Usage:\n./prepare_dockerfile.sh\n\t\
-a <architecture to use (must be defined in config file)>\n\t\
-c <path to config file>\n\t\
-d <path to Dockerfile template>\n\t\
-v <enables more verbose output>\n"
}

while getopts 'a:c:d:vh' flag; do
  case "${flag}" in
    a) ARCH=${OPTARG};;
    c) CONFIGFILE_PATH=${OPTARG};;
    d) DOCKERFILE_PATH=${OPTARG};;
    v) VERBOSE="TRUE";;
    h) print_usage
       exit 1;;
    *) print_usage
       exit 1;;
  esac
done

if [ ! -f "$CONFIGFILE_PATH" ]; then
  printf "ERROR: Config file %s does not exist\n" "$CONFIGFILE_PATH"
  exit 1
fi
if [ ! -f "$DOCKERFILE_PATH" ]; then
  printf "ERROR: Dockerfile %s does not exist\n" "$DOCKERFILE_PATH"
  exit 1
fi

OLDIFS="$IFS"
IFS=''
while read LINE; do
  if echo $LINE | grep -q "^#+"; then
    continue
  fi
  if ! echo $LINE | grep -Eq "^[[:space:]]+"; then
    CONFIG_FIELD="__$(echo "$LINE" | tr -d "[:blank:],:" | tr "[:lower:]" "[:upper:]")__"
    continue
  fi
  if echo $LINE | grep -Eq "^[[:space:]]+$ARCH"; then
    CONFIG_VALUE=$(echo $LINE | grep -Eo ":[[:space:]]+.+$" | tr -d "[:blank:]" | sed "s/^://")
    if [ "$VERBOSE" == "TRUE" ]; then
      printf "Substituting \"%s\" with \"%s\" in: %s\n" "$CONFIG_FIELD" "$CONFIG_VALUE" "$DOCKERFILE_PATH"
    fi
    if ! sed -i "s;$CONFIG_FIELD;$CONFIG_VALUE;g" $DOCKERFILE_PATH; then
      printf "ERROR: something went wrong with substitution.\n"
      exit 2
    fi
  fi
done <"$CONFIGFILE_PATH"
IFS="$OLDIFS"
if [ "$VERBOSE" == "TRUE" ]; then
  printf "Prepared Dockerfile:\n"
  cat $DOCKERFILE_PATH
fi
