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

1. Follow the below link to generate credentials for the google cloud project with 'owner' access:

https://console.cloud.google.com/apis/credentials/serviceaccountkey?_ga=2.144950836.-1463502982.1560620228&_gac=1.182916692.1561251554.Cj0KCQjwo7foBRD8ARIsAHTy2wk0zQkCdSdEB0DLmUO5reLVWd62eXYJbXKJoNKMSkG1ebTxTIcOBRYaAgRbEALw_wcB&project=my-project-1471838978127&folder&organizationId


2. Copy the 'CREDENTIALS_FILE.json' file generated in the previous steps to below locations:
(./host-jenkins/service-account, ./host-kubernetes/host-kubernetes-master/service-account, ./host-kubernetes/host-kubernetes-worker-nodes/service-account)

3. execute the shell script with the below command:
` sh ./orchestrate.sh`
The orchestrate.sh shell script will then first host jenkins in a google compute engine. As a next step spins up the k8s master. As a 3rd step it creates worker nodes and joins with the master node to form k8s cluster. As a final steps it sets up helm and installs monitoring into the kubernetes cluster.
Before each step described above, terraform will calculate the changes that needs to be applied and asks for user confirmation. Type 'yes' to confirm the step execution or 'No' to simply exit.

Manual steps:

1. use the details in the ./host-jenkins/output to setup the plugins and user details in jenkins. Using the public ip address of jenkins vm open it in the browser http://<public-ip>:8080. Jenkins will ask for the initial password. enter the details from the output folder and install the default plugins.
   
2. use the details in the ./host-kubernetes/deploy-prometheus-grafana/output to login into grafana and create custom dashboards. 

3. configure jenkins with kubeconfig and github creds to create pipelines in jenkins for deploying the guest-book application.

scope of improvement:

* adding more nodes to k8s cluster needs little modifications in the script.

* credentials can be read from the vault directly.

* default network is being used.

* monitoring with persistent volume

* annotations need to be added to service.yaml files for monitoring.



