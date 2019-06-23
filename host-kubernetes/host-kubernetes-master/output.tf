output "k8smaster_instance_public_ip" {
  description = "The public IP of the k8smaster instance"
  value       = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
}