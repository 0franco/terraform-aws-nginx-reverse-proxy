#!/bin/bash
# shellcheck disable=SC2154
set -euo pipefail

dnf upgrade -y
dnf install -y nginx

mkdir -p /etc/nginx/ssl /var/www/html
chmod 755 /etc/nginx/ssl

cat >/usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
<head><title>NGINX proxy ready</title></head>
<body><h1>NGINX proxy ready</h1></body>
</html>
HTML

systemctl enable nginx
systemctl start nginx

if [ "${tls_mode}" = "letsencrypt" ]; then
  dnf install -y certbot python3-certbot-nginx

  mkdir -p /etc/nginx/conf.d
  cat >/etc/nginx/conf.d/letsencrypt-http.conf <<'NGINX'
server {
    listen 80;
    server_name ${domain_name};

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
}
NGINX

  nginx -t
  systemctl reload nginx

  cat >/usr/local/bin/issue-letsencrypt <<'SCRIPT'
#!/bin/bash
set -euo pipefail

staging_flag=""
if [ "${letsencrypt_staging}" = "true" ]; then
  staging_flag="--staging"
fi

certbot --nginx \
  --non-interactive \
  --agree-tos \
  --redirect \
  --email "${letsencrypt_email}" \
  -d "${domain_name}" \
  $staging_flag
SCRIPT

  chmod 750 /usr/local/bin/issue-letsencrypt

  if [ "${letsencrypt_auto_issue}" = "true" ]; then
    /usr/local/bin/issue-letsencrypt
  fi
fi

nginx -t
systemctl reload nginx

echo "NGINX proxy setup complete"
