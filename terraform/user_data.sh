#!/bin/bash
set -euxo pipefail

# System update + basic tools
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y nginx ufw fail2ban awscli unzip

# Create a deploy user (no password login)
useradd -m -s /bin/bash deploy
mkdir -p /home/deploy/.ssh
cp /home/ubuntu/.ssh/authorized_keys /home/deploy/.ssh/ || true
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
usermod -aG sudo deploy

# SSH hardening
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

# UFW basic rules
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# Nginx default site
cat >/var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Linux Admin: Production Web</title></head>
<body>
<h1>It works! ✅</h1>
<p>Hardened Ubuntu + Nginx + CloudWatch + S3 backups.</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx

# CloudWatch Agent
CW_DIR=/opt/aws/amazon-cloudwatch-agent
mkdir -p $CW_DIR
cat >$CW_DIR/config.json <<'JSON'
{
  "agent": { "metrics_collection_interval": 60, "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log" },
  "metrics": {
    "namespace": "Custom/LinuxAdmin",
    "append_dimensions": { "InstanceId": "$${aws:InstanceId}" },
    "metrics_collected": {
      "cpu":   {"measurement": ["cpu_usage_idle","cpu_usage_user","cpu_usage_system"], "totalcpu": true},
      "mem":   {"measurement": ["mem_used_percent"]},
      "disk":  {"measurement": ["used_percent"], "resources": ["*"]},
      "net":   {"measurement": ["bytes_in","bytes_out"], "resources": ["*"]}
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/syslog", "log_group_name": "syslog", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "nginx-access", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/error.log", "log_group_name": "nginx-error", "log_stream_name": "{instance_id}" }
        ]
      }
    }
  }
}
JSON

curl -sSLo /tmp/cwagent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i /tmp/cwagent.deb
systemctl enable amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:$CW_DIR/config.json -s

# Backup script + cron (web root & nginx conf)
mkdir -p /opt/linux-admin
cat >/opt/linux-admin/backup.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
TS="$(date +%F-%H%M%S)"
SRC1="/var/www/html"
SRC2="/etc/nginx"
BUCKET="__BUCKET__"
aws s3 sync "$SRC1" "s3://$BUCKET/backup/$TS/var-www-html/" --only-show-errors
aws s3 sync "$SRC2" "s3://$BUCKET/backup/$TS/etc-nginx/" --only-show-errors
echo "$(date) Backup complete to s3://$BUCKET/backup/$TS" >> /var/log/backup.log
BASH
sed -i "s/__BUCKET__/${backup_bucket}/g" /opt/linux-admin/backup.sh
chmod +x /opt/linux-admin/backup.sh

# Cron at 02:15 daily
( crontab -l 2>/dev/null; echo "15 2 * * * /opt/linux-admin/backup.sh" ) | crontab -
