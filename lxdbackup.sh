#!/usr/bin/env bash

# Help message.
usage="$(basename "$0") [-h] [-w -d -m] <container paths relative to /var/lib/lxd/containers/  i.e.. rootfs/var/spool/koha/> -- script for taking backup from lxd
containers.
where:
    -h  show this help text
    -w  weekly
    -d  daily
    -m  monthly
    -b  backup full path
"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

if [[ "$#" -eq 0 ]]; then
        echo -e "[${red}Error${plain}] Please enter some arguments "
    echo "$usage"
    exit 1
fi

weekly= daily= monthly= opath= bpath=
while getopts ':wdmb:h' opt; do
    case $opt in

        w)  weekly=True
            ;;

        d)  daily=True
            ;;
        m)  monthly=True
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

if [[ -z $sources ]]; then
        echo -e "[${red}Error${plain}] please enter container paths relative to /var/lib/lxd/containers/ i.e.. rootfs/var/spool/koha/"
    echo "$usage"
    exit 1
fi

if [[ -z $bpath ]];then
  #change it to /backup before putting it on production
  bpath="/backup/"
fi

# [[ -d /var/lib/lxd/containers/  ]] && echo -e "[${red}Error${plain}] Can't find /var/lib/lxd/containers/.. Please install lxd" && exit 1

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
        find $1 -mindepth 1 -maxdepth 1 -type f -ctime +1 -exec rm {} \; -exec echo -e "[Deleted] {}" >> /var/log/containers/${2}"_deleted".log \;
}

function take_backup {
    # make backup dir
        mkdir -p "$2/$3/"
        mkdir -p /var/log/containers/
        
        if [[ $3 == "daily" ]];then
          find ${2}/${3}/ -mindepth 1 -maxdepth 1 -type f -ctime +0 -exec rm {} \;
        fi
        
        find $1 -mindepth 1 -maxdepth 1 -type f -ctime 1 -exec cp {} ${2}/${3}/ \; -exec echo -e "[BackedUp] {}" >> /var/log/containers/${4}_${3}.log \;

        # anything but today's backhup for removing of daily backup (sure as hell)
        # find . -mindepth 1 -maxdepth 1 -type f -ctime +0 -print
}



for path in "${available_paths[@]}"; do

  # change 5 to 6 before putting it on production
  postfix=$(echo "$path" | cut -d '/'  -f 6)
  fullbpath=${bpath}$postfix
  mkdir -p $fullbpath

  if [[ $weekly == "True" ]];then
    take_backup $path $fullbpath "weekly" $postfix
  fi

  if [[ $daily == "True" ]];then
    take_backup $path $fullbpath "daily" $postfix
  fi
  if [[ $monthly == "True" ]];then
    take_backup $path $fullbpath "monthly" $postfix
  fi

    remove_old $path $postfix
done
