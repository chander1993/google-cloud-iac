// Configure the Google Cloud provider
provider "google" {
 credentials = "${file("./service-account/CREDENTIALS_FILE.json")}"
 project     = "prismatic-iris-243515"
 region      = "asia-south1"
}

// Network firewall policies reference: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
resource "google_compute_firewall" "gh-9564-firewall-master" {
  name    = "gh-9564-firewall-master"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2379-2380", "10250", "10251", "10252", "22", "6443","8081","8443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "default" {
  name         = "mstakx-k8s-master"
  machine_type = "n1-standard-2"
  zone         = "asia-south1-a"

  tags = ["k8s-master"]

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
      host = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
      user = "root"
      private_key = "${file("./ssh-keys/google-jenkins-mstax")}"
      agent = false
    }
    source      = "./scripts/install-master.sh"
    destination = "/tmp/install-master.sh"
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
      "echo 'TESTING ${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}'",
      "sudo sh /tmp/install-master.sh",
      "kubeadm init   --apiserver-cert-extra-sans=${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://docs.projectcalico.org/v3.7/manifests/calico.yaml",
    ]
  }

  metadata = {
    ssh-keys = "root:${file("./ssh-keys/google-jenkins-mstax.pub")}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

}
