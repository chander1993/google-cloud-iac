// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("./service-account/CREDENTIALS_FILE.json")}"
 project     = "prismatic-iris-243515"
 region      = "asia-south1"
}

resource "google_compute_firewall" "gh-9564-firewall-worker" {
  name    = "gh-9564-firewall-worker"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["10250", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_instance" "worker1" {
  name         = "mstakx-k8s-worker1"
  machine_type = "n1-standard-2"
  zone         = "asia-south1-a"

  tags = ["k8s-worker"]

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

  provisioner "file" {
    connection {
      type = "ssh"
      host = "${google_compute_instance.worker1.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }
    source      = "./scripts/install-worker.sh"
    destination = "/tmp/install-worker.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${google_compute_instance.worker1.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }

    inline = [
      "sudo sh /tmp/install-worker.sh",
    ]
  }

  metadata = {
    ssh-keys = "root:${file("./ssh-keys/google-jenkins-mstax.pub")}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

}

resource "google_compute_instance" "worker2" {
  name         = "mstakx-k8s-worker2"
  machine_type = "n1-standard-2"
  zone         = "asia-south1-a"

  tags = ["k8s-worker"]

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

  provisioner "file" {
    connection {
      type = "ssh"
      host = "${google_compute_instance.worker2.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }
    source      = "./scripts/install-worker.sh"
    destination = "/tmp/install-worker.sh"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = "${google_compute_instance.worker2.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }

    inline = [
      "sudo sh /tmp/install-worker.sh",
    ]
  }

  metadata = {
    ssh-keys = "root:${file("./ssh-keys/google-jenkins-mstax.pub")}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

}
