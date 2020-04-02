#!/bin/bash
# you can add pam and firewall rules to restrict the opening of ports on the remote server, see pam_time.so and firewall-cmd with cron
KEY="AF779YF8" # CHANGEME
BACKUP_DOC="/"
REMOTE_SERVER="xxx.xxx.xxx.xxx" # CHANGEME
USER="matt" # CHANGEME
DEST_DIR="remotedata/`hostname -f`"
DEST="rsync://$USER@$REMOTE_SERVER/$DEST_DIR"

apt update && apt install duplicity -y

ssh $USER@$REMOTE_SERVER "mkdir -p $DEST_DIR"

PASSPHRASE="blablablah" \
duplicity --encrypt-key $KEY \
          --exclude=/proc \
          --exclude=/sys \
          --exclude=/mnt \
          --exclude=/tmp \
          --exclude=/dev \
          --exclude=/var/spool \
          --exclude=/var/cache \
          --exclude=/var/tmp \
          $BACKUP_DOC \
          $DEST
exit 0
#EOF
