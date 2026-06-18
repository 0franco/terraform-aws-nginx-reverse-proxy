# NGINX Proxy on AWS

Terraform for a small AWS EC2 instance running NGINX as a public reverse proxy for private application servers.

By default this creates a minimal VPC, public subnet, security group, Elastic IP, and Amazon Linux 2023 ARM instance. You can also deploy into an existing VPC and subnet.

## Requirements

- Terraform 1.15.6 or newer
- AWS credentials configured locally
- A CIDR for SSH access, usually your public IP with `/32`

## Quick Start

```sh
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
ssh_cidr   = "1.1.1.1/32"
```

Deploy:

```sh
terraform init
terraform plan
terraform apply
terraform output
```

`proxy_public_ip` is the Elastic IP by default. Set `enable_elastic_ip = false` if you do not want Terraform to allocate one.

Connect to the instance:

```sh
terraform output -raw generated_private_key_pem > nginx-proxy-ssh.pem
chmod 600 nginx-proxy-ssh.pem
ssh -i nginx-proxy-ssh.pem ec2-user@$(terraform output -raw proxy_public_ip)
```

To use an existing AWS key pair instead of a generated key:

```hcl
create_ssh_key = false
key_name       = "your-aws-key-pair-name"
```

## Existing VPC

To deploy into an existing public subnet:

```hcl
create_vpc = false
vpc_id     = "vpc-xxxxxxxx"
subnet_id  = "subnet-xxxxxxxx"
```

The subnet must have a route to an internet gateway if the proxy should receive public traffic.

## TLS

### Manual Certificates

Manual TLS is the default:

```hcl
tls_mode = "manual"
```

Upload your certificate and key after deploy:

```sh
scp cert.cert ec2-user@PROXY_PUBLIC_IP:/tmp/
scp cert.key ec2-user@PROXY_PUBLIC_IP:/tmp/
ssh ec2-user@PROXY_PUBLIC_IP
sudo mv /tmp/cert.cert /tmp/cert.key /etc/nginx/ssl/
sudo chmod 644 /etc/nginx/ssl/cert.cert
sudo chmod 600 /etc/nginx/ssl/cert.key
sudo nginx -t
sudo systemctl reload nginx
```

### Let's Encrypt

Configure the domain and email:

```hcl
tls_mode          = "letsencrypt"
domain_name       = "app.example.com"
letsencrypt_email = "admin@example.com"
```

Apply, point DNS at `proxy_public_ip`, then run issuance:

```sh
ssh ec2-user@PROXY_PUBLIC_IP
sudo /usr/local/bin/issue-letsencrypt
```

If DNS already points to this instance before first boot, you can issue during bootstrap:

```hcl
letsencrypt_auto_issue = true
```

Use staging while testing issuance:

```hcl
letsencrypt_staging = true
```

## NGINX App Configs

Example configs live in `app-examples/`:

- `nginx.app.conf`: standard HTTPS reverse proxy
- `nginx.websocket.conf`: WebSocket reverse proxy
- `nginx.cached.conf`: static asset caching at the proxy

Copy one to the proxy, edit placeholders, and enable it:

```sh
scp app-examples/nginx.app.conf ec2-user@PROXY_PUBLIC_IP:/tmp/app.conf
ssh ec2-user@PROXY_PUBLIC_IP
sudo cp /tmp/app.conf /etc/nginx/conf.d/app.conf
sudo nano /etc/nginx/conf.d/app.conf
sudo nginx -t
sudo systemctl reload nginx
```

Replace:

- `DOMAIN_NAME` with your domain
- `BACKEND_PRIVATE_IP` with the private IP of your application server
- `BACKEND_PORT` with the application port
- `SSL_CERTIFICATE_PATH` with `/etc/nginx/ssl/cert.cert` for manual TLS or `/etc/letsencrypt/live/DOMAIN_NAME/fullchain.pem` for Let's Encrypt
- `SSL_CERTIFICATE_KEY_PATH` with `/etc/nginx/ssl/cert.key` for manual TLS or `/etc/letsencrypt/live/DOMAIN_NAME/privkey.pem` for Let's Encrypt

For the backend instance security group, allow the application port from `proxy_private_ip` only.

## Security Notes

- `ssh_cidr` cannot be `0.0.0.0/0`; use your current IP with `/32`.
- Generated SSH private keys are stored in Terraform state. Protect state access or use an existing AWS key pair.
- Elastic IPs can incur AWS charges when allocated and not associated with a running instance.
- HTTP and HTTPS are public by default through `http_cidrs` and `https_cidrs`.
- Backend application ports should not be open to the internet.
- Terraform state can contain infrastructure identifiers. Store it according to your team security requirements.

## Troubleshooting

502 Bad Gateway:

```sh
sudo tail -f /var/log/nginx/error.log
curl http://BACKEND_PRIVATE_IP:BACKEND_PORT
```

Check that the backend service is running, the backend security group allows traffic from `proxy_private_ip`, and the NGINX config uses the correct private IP and port.

TLS errors:

```sh
sudo nginx -t
sudo certbot certificates
```

For manual TLS, verify files exist in `/etc/nginx/ssl/` and the private key is readable by root.

Destroy:

```sh
terraform destroy
```

## 🤝 Contributing

Contribute! Please open an issue or submit a pull request.

<a href="https://www.buymeacoffee.com/travelingcode" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/default-red.png" alt="Buy Me A Coffee" height="41" width="174" style="border-radius:10px">
</a>