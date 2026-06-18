#!/bin/bash
# shellcheck disable=SC2154
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y
apt-get install -y nginx

mkdir -p /etc/nginx/ssl /var/www/html
chmod 755 /etc/nginx/ssl

cat >/var/www/html/index.nginx-debian.html <<'HTML'
<!doctype html>
<html>
<head><title>NGINX proxy ready</title></head>
<body><h1>NGINX proxy ready</h1></body>
</html>
HTML

systemctl enable nginx
systemctl start nginx

if [ "${tls_mode}" = "letsencrypt" ]; then
  apt-get install -y certbot python3-certbot-nginx

  cat >/etc/nginx/sites-available/letsencrypt-http <<'NGINX'
server {
    listen 80;
    server_name ${domain_name};

    location / {
        root /var/www/html;
        index index.nginx-debian.html;
    }
}
NGINX

  ln -sf /etc/nginx/sites-available/letsencrypt-http /etc/nginx/sites-enabled/letsencrypt-http
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
