// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("./service-account/CREDENTIALS_FILE.json")}"
 project     = "prismatic-iris-243515"
 region      = "asia-south1"
}

resource "google_compute_firewall" "gh-9564-firewall-externalssh" {
  name    = "gh-9564-firewall-externalssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins"]
}

resource "google_compute_firewall" "gh-8080-firewall-jenkins" {
  name    = "gh-8080-firewall-jenkins"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins"]
}

resource "google_compute_instance" "default" {
  name         = "mstakx-jenkins"
  machine_type = "n1-standard-2"
  zone         = "asia-south1-a"

  tags = ["jenkins"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }

    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y default-jre",
      
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -",
      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt update",
      "sudo apt -y install jenkins",
    ]
  }
  depends_on = ["google_compute_firewall.gh-9564-firewall-externalssh"]

  metadata = {
    ssh-keys = "root:${file("./ssh-keys/google-jenkins-mstax.pub")}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

}


