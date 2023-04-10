#!/bin/bash

# create a repository to store the docker image in docker hub 
# launch an ec2 instance. open port 80 and port 22. this will be inside terraform-nn2-ec2.tf file

# install and configure docker on the ec2 instance - this is done in this file

sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# create a dockerfile

# build the docker image
sudo docker build -t terraform-nn2 .

# login to your docker hub account
cat ~/my_password.txt | sudo docker login --username niyiajiteru --password-stdin

# use the docker tag command to give the image a new name
sudo docker tag terraform-nn2  niyiajiteru/terraform-nn2 

# push the image to your docker hub repository
sudo docker push niyiajiteru/terraform-nn2 

# start the container to test the image 
sudo docker run -dp 80:80 niyiajiteru/terraform-nn2 

# references
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html
# https://docs.docker.com/get-started/02_our_app/
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html#create-container-image-install-docker