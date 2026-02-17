# File2Object

**File2Object** is a lightweight automation service that performs **real-time synchronization from local filesystem directories to S3-compatible object storage** using event-driven triggers.

This project is designed for environments such as:

* ISP / Telco backup systems (OLT, router, network configs)
* FTP backup pipelines
* Edge storage replication
* Automated object storage ingestion
* Infrastructure / DevOps workflows

File changes are detected instantly using Linux **inotify**, then mirrored to object storage using **MinIO Client (mc)**.

---

# Architecture Overview

```
FTP Server → Local Directory → File2Object Watcher → Object Storage (RustFS / S3)
```

Workflow:

1. Device uploads backup to FTP server
2. File stored in local directory
3. File2Object detects filesystem event
4. Automatic mirror to Object Storage
5. Storage stays synchronized in near real-time

---

# Features

* Real-time file monitoring (no cron delay)
* S3 compatible (RustFS, MinIO, AWS S3, Ceph, etc.)
* Automatic sync on create / modify / delete
* One-way mirror with cleanup support
* Lightweight and low resource usage
* Systemd service integration
* Production-ready logging

---

# Requirements

* Linux server (Ubuntu / Debian recommended)
* Root or sudo privileges
* FTP server installed (optional but common use case)
* RustFS / S3 compatible object storage running
* Internet access to download MinIO Client

Packages:

```
inotify-tools
wget
```

---

# Installation

## 1. Install Dependencies

```bash
apt update
apt install inotify-tools wget -y
```

---

## 2. Install MinIO Client (mc)

Download binary:

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/mcli
```

Verify installation:

```bash
mcli --version
```

---

## 3. Configure Object Storage Connection

Set alias to RustFS (S3 compatible):

```bash
mcli alias set rustfs http://127.0.0.1:9000 ACCESS_KEY SECRET_KEY
```

Test connection:

```bash
mcli ls rustfs
```

Create bucket if needed:

```bash
mcli mb rustfs/backup-olts
```

---

# Configuration

Create watcher script:

```bash
nano /usr/local/bin/file2object.sh
```

Script:

```bash
#!/bin/bash

SOURCE="/home/ftp-backup/backup-files"
TARGET="localrust/backup-files"
LOG="/var/log/file2object.log"

inotifywait -m -r -e modify,create,delete,move "$SOURCE" |
while read path action file; do
    echo "$(date) - Change detected: $action $path$file" >> $LOG
    /usr/local/bin/mcli mirror --overwrite --remove "$SOURCE" "$TARGET" >> $LOG 2>&1
done
```

Make executable:

```bash
chmod +x /usr/local/bin/file2object.sh
```

---

# Systemd Service

Create service file:

```bash
nano /etc/systemd/system/file2object.service
```

Service configuration:

```ini
[Unit]
Description=File2Object Realtime Sync Service
After=network.target

[Service]
ExecStart=/usr/local/bin/file2object.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now file2object
```

Check status:

```bash
systemctl status file2object
```

---

# Logging

Logs stored at:

```
/var/log/file2object.log
```

View logs:

```bash
tail -f /var/log/file2object.log
```

---

# Testing

Create test file:

```bash
touch /home/ftp-backup/backup-olts/test.txt
```

Verify object storage:

```bash
mcli ls rustfs/backup-olts
```

---

# Optional (Recommended)

Enable bucket versioning:

```bash
mcli version enable rustfs/backup-olts
```

This protects data from accidental deletion when using `--remove`.

---

# Use Cases

* OLT automatic backup ingestion
* Router configuration archival
* Network infrastructure backup
* FTP to Object Storage bridge
* Edge data replication
* DevOps artifact ingestion

---

# Performance Notes

* Suitable for thousands of files
* Minimal CPU usage
* Event-driven (no polling)
* Mirror execution depends on storage latency

For very large datasets consider batching or scheduled sync intervals.

---
