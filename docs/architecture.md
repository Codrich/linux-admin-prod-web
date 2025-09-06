# Architecture (Overview)

- **Goal:** Production-like Linux host serving web content with monitoring & backups.
- **Infra:** Default VPC, single public subnet, EC2 Ubuntu 22.04, SG (80/443 to world; 22 only from your IP), IAM role/profile.
- **Config:** cloud-init hardening, Nginx, CloudWatch Agent, cron S3 backups.
- **Ops:** CPU alarm, logs in CloudWatch, nightly S3 snapshots, Ansible for drift.
