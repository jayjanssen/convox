#!/bin/bash
set -ex -o pipefail

# install utilities
sudo apt-get update && sudo apt-get -y install jq unzip

# install aws cli
sudo apt-get -y install awscli

# install aws-iam-authenticator
curl -Ls https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator -o /tmp/aws-iam-authenticator && \
	sudo mv /tmp/aws-iam-authenticator /usr/bin/aws-iam-authenticator && sudo chmod +x /usr/bin/aws-iam-authenticator

# install docker
curl -s https://download.docker.com/linux/static/stable/x86_64/docker-18.09.6.tgz | sudo tar -C /usr/bin --strip-components 1 -xz

# install kubectl
curl -Ls https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl -o /tmp/kubectl && \
	sudo mv /tmp/kubectl /usr/bin/kubectl && sudo chmod +x /usr/bin/kubectl

# install terraform
curl -L https://releases.hashicorp.com/terraform/0.13.2/terraform_0.13.2_linux_amd64.zip -o terraform.zip && \
	unzip terraform.zip -d /tmp && sudo mv /tmp/terraform /usr/bin/terraform && rm terraform.zip