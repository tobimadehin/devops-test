resource "digitalocean_droplet" "my_droplet" {
    name      = "my-droplet-${count.index + 1}"
    region    = "nyc3"
    size      = "s-1vcpu-1gb"
    image     = "ubuntu-20-04-x64"
    count     = 3
    ssh_keys  = [digitalocean_ssh_key.my_ssh_key.id]
}

resource "digitalocean_ssh_key" "my_ssh_key" {
  name = "my_ssh_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "digitalocean_certificate" "my_ssl_certificate" {
  name       = "my-ssl-certificate"
  private_key = file("key.pem")
  leaf_certificate = file("certificate.crt")
}

resource "digitalocean_loadbalancer" "public" {
  name   = "my-loadbalancer"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 80
    target_protocol = "http"

    certificate_name = digitalocean_certificate.my_ssl_certificate.name
  }

  droplet_ids = [for droplet in digitalocean_droplet.my_droplet : droplet.id]
}

resource "digitalocean_firewall" "my-firewall" {
  name = "my-firewall"

  droplet_ids = [for droplet in digitalocean_droplet.my_droplet : droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "all"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}
