#!/usr/bin/env bash

# Help message.
usage="$(basename "$0") [-h] [-w -d] -- script for taking backup from lxd
containers.

where:
    -h  show this help text
    -w  weakly
    -d  daily
    -b  backup full path
"
weakly= daily= opath= bpath=
while getopts ':wdb:h' opt; do
    case $opt in

        w)  weakly=True
            ;;

        d)  daily=True
            ;;
        b)  bpath=$OPTARG
            ;;
        h)  echo "$usage"
            exit
            ;;
        '?')    echo "$0: invalid option -$OPTARG" >&2
                echo "$usage" >&2
                exit 1
                ;;
    esac
done
shift $(($OPTIND -1)) # Remove options, leave arguments.
sources=$1

if [[ -z $bpath ]];then
  #change it to /backup before putting it on production
  bpath="/backup/"
fi

red='\033[0;31m'
green='\033[0;32m'
plain='\033[0m'

 #"/var/lib/lxd/containers/www-pnumag-com/rootfs/var/spool/koha/"

available_paths=()
# put /var before putting it on production
for dir in /var/lib/lxd/containers/*; do
  for path in $dir; do
  fpath=${path}/$sources
   if [[ -d "$fpath" ]]; then
     available_paths+=("$fpath")
   fi
  done
done


function remove_old {
       #k #find $path -type f -mtime +7  -execdir rm -- {} \;
       #k  find $path -type f -mtime +7  -print
# This should be changed to remove instead of printing.
             mkdir -p /var/log/containers/
             find $1 -mindepth 1 -maxdepth 1 -type f -ctime +2  -print -exec echo -e "[${red}Deleted${plain}] {}" >> /var/log/containers/${2}"_deleted".log \;
}

function take_backup {
        mkdir -p "$2$3"
        mkdir -p /var/log/containers/
        find $1 -mindepth 1 -maxdepth 1 -type f -daystart -ctime 1 -exec echo -e "[${green}BackedUp${plain}] {}" >> /var/log/containers/$4.log \;
}



for path in "${available_paths[@]}"; do

  # change 5 to 6 before putting it on production
  # makr sure parent backup dir is availabl
  postfix=$(echo "$path" | cut -d '/'  -f 6)
  echo $postfix
  fullbpath=${bpath}$postfix
  mkdir -p $fullbpath

  if [[ $weakly == "True" ]];then
    take_backup $path $fullbpath "/weakly/" $postfix
  fi

  if [[ $daily == "True" ]];then
    take_backup $path $fullbpath "/daily/" $postfix
  fi

    remove_old $path $postfix
done
