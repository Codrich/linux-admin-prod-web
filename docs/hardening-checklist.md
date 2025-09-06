# Hardening Checklist

- [x] SSH key-only, `PermitRootLogin no`, `PasswordAuthentication no`
- [x] UFW enabled; only 22 (from my IP), 80/443
- [x] Fail2ban installed (defaults enabled)
- [x] System packages updated
- [x] Nginx basic security headers
- [x] IAM least privilege for S3 backup bucket
