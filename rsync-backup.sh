#!/usr/bin/env bash

# This uses rsync to sync down remote files to the /data/backups/<hostname>
# directories.
# The rsync command we will use.
RSYNC=`which rsync`
RSYNC_OPTS="-av "

# Host list - Bash array - You can add hosts in the .ssh/config of your script's user
HOSTLIST='
ns1
ns2
'
# Back up directory on local host and source directory on remote host
BACKUP_DIR='/data/backups'
ZONES_DIR='/var/lib/knot'

# excluded directory
EXCLUDED="/tmp"

# error function
error_check() {
    if [ $1 -eq 0 ] ; then
    echo "backup successful"
    else
    echo "backup failed: see error number: $1"
    fi
}

# The rsync functions
get_zones() {
  ${RSYNC} ${RSYNC_OPTS} --exclude $EXCLUDED $HOST:$ZONES_DIR $BACKUP_DIR/$HOST 2>&1 > /dev/null
}

# Bash for loop to go through each host and rsync the data.
for HOST in $HOSTLIST ; do
  get_zones
  error_check $?
done

exit 0
#EOF
