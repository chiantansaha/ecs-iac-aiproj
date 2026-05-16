# Self-signed certificate for internal ALB (development/demo purposes)
# Note: This is not recommended for production use

resource "tls_private_key" "main" {
  count = var.create_self_signed_cert ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "main" {
  count = var.create_self_signed_cert ? 1 : 0

  private_key_pem = tls_private_key.main[0].private_key_pem

  subject {
    common_name  = "*.elb.amazonaws.com"
    organization = "Meridian Demo"
  }

  dns_names = [
    "*.elb.amazonaws.com",
    "*.ap-southeast-2.elb.amazonaws.com",
    "internal-meridianagentcore-910045470.ap-southeast-2.elb.amazonaws.com"
  ]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed" {
  count = var.create_self_signed_cert ? 1 : 0

  private_key      = tls_private_key.main[0].private_key_pem
  certificate_body = tls_self_signed_cert.main[0].cert_pem

  tags = merge(var.tags, {
    Name = "${var.name}-self-signed-certificate"
  })
}