#!/bin/bash
######################################################################
# Comando/script para nlistar los repos en github de algún usuario
######################################################################

[ $1 ] && U="$1" 
[ ! $1 ] && echo "Falta el nombre de usuario." && exit 1 

REPOS=($(curl "https://api.github.com/users/$U/repos" 2>/dev/null  | sed 's/"//g'| sed 's/,//g' |  grep html_url | awk -F: '{print $2 ":" $3}' | sort | uniq))

echo ${REPOS[*]}
