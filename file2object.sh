#!/bin/bash

SOURCE="/home/ftp-backup/backup-files"
TARGET="localrust/backup-files"
LOG="/var/log/file2object.log"

inotifywait -m -r -e modify,create,delete,move "$SOURCE" |
while read path action file; do
    echo "$(date) - Change detected: $action $path$file" >> $LOG
    /usr/local/bin/mcli mirror --overwrite --remove "$SOURCE" "$TARGET" >> $LOG 2>&1
done