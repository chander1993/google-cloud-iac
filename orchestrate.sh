#!/bin/sh 

#-------------------- install jenkins -------------------------#

## changes to host jenkins directory
cd ./host-jenkins

## intialized terraform with google cloud provider, project, etc
terraform init

## calculating the actions based required to be taken in the google cloud environment based on the tf.state and the current cloud state.
terraform plan -out run.plan

## Confirms with the user whether the actions calculated in the previous step can be executed or not
while true; do
    read -p "Are you sure, you want to deploy all these resources to host jenkins?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

## clears the previous execution log file
rm -f ./output/logfilejenkins
rm -f ./output/jenkins_ip
rm -f ./output/initialAdminPassword
## applying the calculated actions to google Cloud project
terraform apply run.plan | tee -a ./output/logfilejenkins

## reads the jenkins from the logfile and copies to jenkins_ip file for future reference
cat ./output/logfilejenkins | grep 'jenkins_instance_public_ip' > ./output/jenkins_ip

## assigns the jenkins ip address to a variable. sed command removes the color code.
jenkins_ip="$(cat ./output/jenkins_ip | awk '{print$3}' | sed 's/\x1b\[[0-9;]*m//g')" 

## copies the initial jenkins password file to local machine for future reference.
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./ssh-keys/google-jenkins-mstax root@$jenkins_ip:/var/lib/jenkins/secrets/initialAdminPassword ./output/initialAdminPassword

# ------------------------install kubernetes master---------------------#

## changes current directory to host kubernetes master directory
cd ../host-kubernetes/host-kubernetes-master

## intialized terraform with google cloud provider, project, etc
terraform init

## calculating the actions based required to be taken in the google cloud environment based on the tf.state and the current cloud state.
terraform plan -out run.plan

## Confirms with the user whether the actions calculated in the previous step can be executed or not
while true; do
    read -p "Are you sure, you want to deploy all these resources to host k8smaster?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

## clears the previous execution log file
rm -f ./output/logfilek8smaster

## applying the calculated actions to google Cloud project
terraform apply run.plan | tee -a ./output/logfilek8smaster

## Initialize variable
k8smaster_join_ip=""
k8smaster_join_token=""
k8smaster_discovery_token=""
k8smaster_public_ip=""

if grep -q 'kubeadm join' ./output/logfilek8smaster; then
    echo "First time execution"

    #clears all the previous execution files
    rm -f ./output/k8smaster_join_ip
    rm -f ./output/k8smaster_join_token
    rm -f ./output/k8smaster_discovery_token
    rm -f ./output/k8smaster_public_ip
    rm -f ./output/kubeconfig

    ## reads from the logfilek8smaste and copies to k8smasteer_join_ip file for future reference
    cat ./output/logfilek8smaster | grep 'kubeadm join' | awk '{print$5}' > ./output/k8smaster_join_ip

    ## assigns the jenkins ip address to a variable. sed command removes the color code.
    k8smaster_join_ip="$(cat ./output/k8smaster_join_ip)" 

    echo "k8s master joinip: $k8smaster_join_ip"

    ## reads from the logfilek8smaste and copies to k8smasteer_join_token file for future reference
    cat ./output/logfilek8smaster | grep 'kubeadm join' | awk '{print$7}' > ./output/k8smaster_join_token

    ## assigns the jenkins ip address to a variable.
    k8smaster_join_token="$(cat ./output/k8smaster_join_token)" 

    echo "k8s master join token: $k8smaster_join_token"

    ## reads from the logfilek8smaste and copies to k8smasteer_join_ip file for future reference
    cat ./output/logfilek8smaster | grep 'discovery-token-ca-cert-hash' | awk '{print$4}' > ./output/k8smaster_discovery_token

    ## assigns the jenkins ip address to a variable. sed command removes the color code.
    k8smaster_discovery_token="$(cat ./output/k8smaster_discovery_token)" 

    echo "k8s master disoovery token: $k8smaster_discovery_token"

    ## reads the jenkins from the logfile and copies to jenkins_ip file for future reference
    cat ./output/logfilek8smaster | grep 'k8smaster_instance_public_ip' > ./output/k8smaster_public_ip

    ## assigns the k8smaster_public_ip address to a variable. sed command removes the color code.
    k8smaster_public_ip="$(cat ./output/k8smaster_public_ip | awk '{print$3}' | sed 's/\x1b\[[0-9;]*m//g')"

    echo "k8s master public ip: $k8smaster_public_ip"

    ## copies the initial jenkins password file to local machine for future reference.
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ./ssh-keys/google-jenkins-mstax root@$k8smaster_public_ip:/etc/kubernetes/admin.conf ./output/kubeconfig
else
    echo "Resources already created in cloud, just initializing the variables"

    ## assigns the jenkins ip address to a variable.
    k8smaster_join_ip="$(cat ./output/k8smaster_join_ip)"

    echo "k8s master joinip: $k8smaster_join_ip"

    ## assigns the jenkins ip address to a variable.
    k8smaster_join_token="$(cat ./output/k8smaster_join_token)"

    echo "k8s master join token: $k8smaster_join_token"

    ## assigns the jenkins ip address to a variable. sed command removes the color code.
    k8smaster_discovery_token="$(cat ./output/k8smaster_discovery_token)"

    echo "k8s master disoovery token: $k8smaster_discovery_token"

    ## assigns the k8smaster_public_ip address to a variable. sed command removes the color code.
    k8smaster_public_ip="$(cat ./output/k8smaster_public_ip | awk '{print$3}' | sed 's/\x1b\[[0-9;]*m//g')"

     echo "k8s master public ip: $k8smaster_public_ip"

fi

# ------------------------install kubernetes worker nodes---------------------#

## changes current directory to host kubernetes worker nodes directory
cd ../host-kubernetes-worker-nodes

## clears the provision script
rm -f ./scripts/install-worker.sh

cp ./scripts/install-worker.tpl ./scripts/install-worker.sh

# creates provision script from the template file
sed -i "s/{.k8smaster_join_ip}/$k8smaster_join_ip/g" ./scripts/install-worker.sh
sed -i "s/{.k8smaster_join_token}/$k8smaster_join_token/g" ./scripts/install-worker.sh
sed -i "s/{.k8smaster_discovery_token}/$k8smaster_discovery_token/g" ./scripts/install-worker.sh

## intialized terraform with google cloud provider, project, etc
terraform init

## calculating the actions based required to be taken in the google cloud environment based on the tf.state and the current cloud state.
terraform plan -out run.plan

## Confirms with the user whether the actions calculated in the previous step can be executed or not
while true; do
    read -p "Are you sure, you want to deploy all these resources to host k8sworker nodes?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

## clears the previous execution log file
rm -f ./output/logfilek8sworker

## applying the calculated actions to google Cloud project
terraform apply run.plan | tee -a ./output/logfilek8sworker


#--------------- install promethues, grafana, elasticsearch for monitoring--------------------

##------------------Installing prerquisites like curl, kubectl, helm to deploy monioring and elastic search 

# changes directory to monitoring workspace
cd ../deploy-prometheus-grafana

# gets a user confirmation from the user whether to proceed with the monitoring setup or not.
while true; do
    read -p "Do you want to continue deploying grafana and prometheus for monitoring?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# installs curl
if ! [ -x "$(command -v curl )" ]; then
    echo "curl do not exists, installing..."
    sudo apt-get install curl
fi

# installs kuubectl
if ! [ -x "$(command -v kubectl )" ]; then
    echo "kubectl do not exists, installing..."
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

#installs helm
if ! [ -x "$(command -v helm )" ]; then
    echo "helm do not exists, installing..."
    rm -f install-helm.sh
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > install-helm.sh
    chmod u+x install-helm.sh
    ./install-helm.sh
    rm -f install-helm.sh
fi

# configures kubeconfig
if [ ! -d "~/.kube" ]; then
  echo "~/.kube directory does not exist, creating..."
  sudo mkdir ~/.kube
fi

# replaces the internal ip address in the kubconfig with public ip address
sed -i "s/server:.*6443$/server: https:\/\/$k8smaster_public_ip:6443/g" ../host-kubernetes-master/output/kubeconfig

# configures kubeconfig
sudo rm -f $HOME/.kube/config
sudo cp -i ../host-kubernetes-master/output/kubeconfig $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# creates monitoring namespace inside kube cluster
kubectl apply -f monitoring-namespace.yaml

# initializes tiller
kubectl apply -f helm-rbac-config.yaml
helm init --service-account tiller --history-max 200

# sleeps for 30 seconds for giving time for tiller to initialize 
sleep 30s


#  install prometheuss
helm install -f charts/stable/prometheus/values.yaml charts/stable/prometheus --name prometheus --namespace monitoring
rm -f ./output/initialPassword
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo > ./output/initialPassword

# install grafana
helm install -f charts/stable/grafana/values.yaml charts/stable/grafana --name grafana --namespace monitoring

#installs fluentd
helm install -f charts/stable/fluentd/values.yaml charts/stable/fluentd --name fluentd --namespace monitoring

 # installs elasticsearch
helm install -f charts/stable/elasticsearch/values.yaml charts/stable/elasticsearch --name elasticsearch --namespace monitoring

