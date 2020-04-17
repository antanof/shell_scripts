#!/usr/bin/env bash


BACKUP_FILE="$2"
BACKUP_KEY="backup.key"


encrypt(){
	rm -rf $BACKUP_KEY
        tr -dc '[:alnum:]!@#$%^&*_-' < /dev/urandom | fold -w 256 | head -n 1 > $BACKUP_KEY
        chmod 400 $BACKUP_KEY

        openssl enc -in "$BACKUP_FILE" -out "$BACKUP_FILE.enc" -pass file:$BACKUP_KEY -e -md sha512 -salt -aes-256-cbc -iter 100000 -pbkdf2
        rm -rf "$BACKUP_FILE"
}


# Decrypt
decrypt(){
        openssl enc -in "$BACKUP_FILE.enc" -out "$BACKUP_FILE" -pass file:$BACKUP_KEY -d -md sha512 -salt -aes-256-cbc -iter 100000 -pbkdf2
        rm -rf "$BACKUP_FILE.enc"
	rm -rf $BACKUP_KEY
}

$1

exit 0
