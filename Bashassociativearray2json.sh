#!/bin/bash

jsonfile="file.json"
hostnamefile="hostnames.txt"

bash2array () {
declare -A hostnames
for line in $(echo $input); do
	hostnames["$line"]="ssh root@$line cat /etc/chef/cache/chef-stacktrace.out" ;
done

for j in ${!hostnames[@]}; do
	echo $j
	echo ${hostnames[$j]}
done |
jq -n -R 'reduce inputs as $l ({}; . + { ($l): (input|(tostring? // .)) })'
}

i=0
while [ $i -lt `cat "$jsonfile" | jq '. | length'` ] ; do
   tri=`cat "$jsonfile" | jq -r ".[$i].appli_error[]"`
   input=$(for k in ${tri[*]}; do cat "$hostnamefile" | grep $k ; done | sed 's/,//g')
   cat ___error_log.json | jq ".[$i]" | jq --argjson hstnm "`bash2array`" '. |= . + {servers: $hstnm}'
i=$(($i + 1)); done

exit 0

#EOF
