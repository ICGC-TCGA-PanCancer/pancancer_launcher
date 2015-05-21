# pancancer-launcher
Contains the Dockerfile to build the pancancer/pancancer_launcher container

## Introduction

The pancancer_launcher docker container is a docker container that contains all of the nececssary infrastructure to create new pancancer worker nodes which can be used as workers, or as the basis of a new VM snapshot, and start up new VMs based on existing snapshots.

This document will guide you in installing and using this container.

#### Before you begin

Docker containers can be installed on any host machine capable of running docker. This document will assume that you are running on Amazon Web Services. 

If you are unfamiliar with docker, you might want to read about it [here](https://www.docker.com/whatisdocker/).

## Preparing the host machine

#### Installing Docker

Start up a new VM in AWS. You will want to use an Ubuntu 14.04 AMI, and give yourself at least 16 GB for storage space (docker images can take up a bit of space). An m3.large instance type should do just fine.

When you instance has finished starting up, log in to it and install docker. A detailed installation guide can be found [here](https://docs.docker.com/installation/), although installing docker is quite simple, you can simply run this commad:

    wget -qO- https://get.docker.com/ | sh

Once you have docker installed, you will want to give your user access to the "docker" group:

    sudo usermod -aG docker ubuntu

This will save you the trouble of having to "sudo" every docker command. You will need to log out and then log back in for this change to take effect.

To see if your docker installation is working correctly, you can run the "hello world" container:

    docker run hello-world

*(If you have had any problems getting docker installed, you may wish to consult the [detailed installation guide](https://docs.docker.com/installation/))*

#### Installing the pancancer_launcher container

Once you have docker installed, pull the docker image:

    docker pull pancancer/pancancer_launcher

If there is a specific version of the container you wish to pull, you can add the version to the command like this:

    docker pull pancancer/pancancer_launcher:1.0.0

To see further details about the container (such as the available versions/tags), see the [relevant dockerhub page](https://registry.hub.docker.com/u/pancancer/pancancer_launcher/).
