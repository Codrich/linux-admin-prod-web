# Linux Admin: Production Web on AWS (Terraform + Ansible)

This project provisions a hardened Ubuntu EC2 instance with Nginx, CloudWatch Agent, and nightly S3 backups.
It’s designed to showcase real-world Linux administration, automation, monitoring, and security.

## Quick Start

1) **Prereqs**
- AWS account and AWS CLI configured (`aws configure`) – set region to `us-east-1` (N. Virginia)
- Terraform >= 1.5
- SSH key in `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` (or update `variables.tf`)
- An existing S3 bucket for backups (e.g., `my-linux-backups-1234`)

2) **Create S3 bucket (if needed)**
```bash
aws s3 mb s3://<your-backup-bucket> --region us-east-1
```

3) **Deploy**
```bash
cd terraform
terraform init
terraform apply   -var my_ip_cidr="$(curl -s ifconfig.me)/32"   -var backup_bucket="<your-backup-bucket>"
```

4) **Verify**
- Visit `http://<public_ip>` – you should see “It works!”
- SSH in: `ssh -i ~/.ssh/id_rsa ubuntu@<public_ip>`
- Check logs/metrics in CloudWatch (log groups: `syslog`, `nginx-access`, `nginx-error`; metrics namespace `Custom/LinuxAdmin`)
- Trigger a backup manually:
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<public_ip> 'sudo /opt/linux-admin/backup.sh && tail -n2 /var/log/backup.log'
aws s3 ls s3://<your-backup-bucket>/backup/ --recursive --human-readable --summarize
```

5) **Optional: Ansible (Day-2 ops)**
```bash
cd ansible
# Edit inventory.ini to set the public IP
ansible-playbook -i inventory.ini site.yml
```

6) **Teardown**
```bash
cd terraform
terraform destroy
```

## What’s Included
- Terraform for EC2, Security Group, IAM Role/Instance Profile, CloudWatch alarm
- cloud-init (user_data.sh) to harden SSH, configure UFW + Fail2ban, install Nginx, set up CloudWatch Agent, and schedule S3 backups via cron
- Ansible playbook for repeatable config management (optional)
- Docs + scripts for verification

## Next Steps (Nice-to-have)
- Add TLS (Let’s Encrypt / certbot) and redirect HTTP -> HTTPS
- Deploy your app (e.g., Node/Flask/Java, or your Expense Tracker) behind Nginx
- Add systemd units for your app
- Expand monitoring/alerts, e.g., disk space thresholds, 5xx error rates
