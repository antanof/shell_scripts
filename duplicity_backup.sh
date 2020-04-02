#!/bin/bash
# You can add pam and firewall rules to restrict the opening of ports on the remote server, see pam_time.so and firewall-cmd with cron:
# In the remote backup server, for example install with `crontab -e` :
# 0 12 * * * root firewall-cmd --zone=FedoraWorkstation --add-service=ssh
# 0 13 * * * root firewall-cmd --zone=FedoraWorkstation --remove-service=ssh
# and in /etc/security.time.conf
# sshd;*;*;Al1200-1300
# and in /etc/pam.d/sshd before "account required pam_nologin.so"
# account    required     pam_time.so
# In local backup server, add simple task in cron :
# 0 12 * * * root /root/duplicity_backup.sh &
# use pinentry gpg option to hide $PASSPHRASE
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
unset PASSPHRASE
exit 0
#EOF
