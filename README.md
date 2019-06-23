This project sets up infrastructure to host guest-book demo application from kubernetes.

'orchestrate.sh' file in the $PROJECT_HOME is the orchestrator script which sets up below items at one shot:
    * hosts jenkins in gce
    * hosts a full fledged k8s cluster using kubeadm
    * deploys prometheus and grafana for monitoring
    * deploys fluentd and elastic search

This script is documented inline and can find the output folder in each folder subfolders to get the created resource details. 

Explaining the various project structure:
$PROJECT_HOME/host-jenkins hosts jenkins and the output folder inside this folder will hold the initial credentials to login to the system.
$PROJECT_HOME/host-kubernetes hosts kubernetes in gce and the output folder inside this folder also will have some details about the resources created.
$PROJECT_HOME/host-kubernetes/deploy-prometheus-grafana have helm charts required to deploy monitoring solutions like grafana, prometheues, etc

How to run the orchestrator script?

` sh ./orchestrate.sh'
This command creates all the resources into the Google cloud, except the actual application deployment.
Note: for security reasons CREDENTIALS file is not pushed into the github. please follow the below link to generate credentials for your project and place it in these places(./host-jenkins/service-account, ./host-kubernetes/host-kubernetes-master/service-account, ./host-kubernetes/host-kubernetes-worker-nodes/service-account):
https://console.cloud.google.com/apis/credentials/serviceaccountkey?_ga=2.144950836.-1463502982.1560620228&_gac=1.182916692.1561251554.Cj0KCQjwo7foBRD8ARIsAHTy2wk0zQkCdSdEB0DLmUO5reLVWd62eXYJbXKJoNKMSkG1ebTxTIcOBRYaAgRbEALw_wcB&project=my-project-1471838978127&folder&organizationId

Manual steps:

1. use the details in the ./host-jenkins to setup the plugins and user details in jenkins.
2. use the details in the ./host-kubernetes/deploy-prometheus/grafana to login into grafana and create custom dashboards.
3. configure jenkins with kubeconfig and github creds to create pipelines in jenkins for deploying the guest-book application.

scope of improvement:

* adding more nodes to k8s cluster needs little modifications in the script.

* credentials can be read from the vault directly.

* default network is being used.

* monitoring with persistent volume

* annotations need to be added to service.yaml files for monitoring.



