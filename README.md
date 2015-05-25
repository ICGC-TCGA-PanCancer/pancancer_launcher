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

#### Setting up your SSH pem keys.

The pancancer_launcher can start up new VMs on AWS. To do this, it needs access to the SSH pem key that you want to use for this purpose. Please make sure that you have copied your pem key to the host machine, and placed it in `~/.ssh`.

## Starting the container

The easiest way to start up the pancancer_launcher container is to use a helper script. You can get the helper script like this:

    wget https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/architecture-setup/feature/dockerize-launcher/start_launcher_container.sh
    
The script takes two arguments:
 - The path to the pem key that you want to use for new worker VMs
 - The version/tag of the container you wish to start.

Executing the script can look like this:

    bash start_launcher_container.sh ~/.ssh/my_key.pem latest

This should start up your container.

## Setting up the container

Once the container has started, you should have a fully functional launcher host that is capable of running Bindle to create new worker nodes.
    
You are now ready to run Bindle to create a new VM!

### Running Bindle

Bindle is a toolset that can create new VMs, and install workflows and all of their necessary dependencies onto the VMs. You can learn more about Bindle [here](https://github.com/CloudBindle/Bindle#about-bindle).

If you wish to run Bindle, the first thing you will need to do is edit your Bindle configuration file. For AWS, this file is located at `~/.bindle/aws.cfg`.

A sample bindle config file for AWS looks like this:

    [defaults]
    platform = aws
    aws_key = <Your AWS Key>
    aws_secret_key = <Your AWS Secret Key>
    aws_instance_type = 'm1.xlarge' 
    aws_region = 'us-east-1'
    aws_zone = nil 
    aws_image = 'ami-a73264ce'
    aws_ssh_username = ubuntu
    aws_ssh_key_name = sshorser-2 
    aws_ssh_pem_file = '/home/ubuntu/.ssh/sshorser-2.pem'
    aws_ebs_vols = "aws.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 100 },{'DeviceName' => '/dev/sdb', 'NoDevice' => '' }]"
    # For any single node cluster or a cluster in bionimbus environment, please leave this empty(Ex. '')
    # Else for a multi-node cluster, please specify the devices you want to use to setup gluster
    # To find out the list of devices you can use, execute “df | grep /dev/” on an instance currently running on the same platform.
    # (Ex. '--whitelist b,f' if you want to use sdb/xvdb and sdf/xvdf). 
    # Note, if your env. doesn't have devices, use the gluster_directory_path param
    gluster_device_whitelist=''
    # For any single node cluster or a cluster in bionimbus environment, please leave this empty(Ex. '')
    # Else for a multi-node cluster, please specify the directory if you are not using devices to set up gluster
    # (Ex. '--directorypath /mnt/volumes/gluster1')
    gluster_directory_path=''
    box = dummy
    box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'
    host_inventory_file_path=ansible_host_inventory.ini
    ansible_playbook = ../container-host-bag/install.yml
    seqware_provider=artifactory
    seqware_version='1.1.0'
    # used by test framework; ignore it if you are launching clusters through bindle
    number_of_clusters = 1
    number_of_single_node_clusters = 1
    bwa_workflow_version = 2.6.3
    # Do you want to install a docker container that already contains seqware and all of its dependencies?
    seqware_in_container=true
    # The names of the workflows
    workflow_name=HelloWorld,Sanger,BWA,DEWrapper
    # The specific bundle names of the workflows
    workflows=Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.1,Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_1.0.6_SeqWare_1.1.0,Workflow_Bundle_DEWrapperWorkflow_1.0.2_SeqWare_1.1.0,Workflow_Bundle_BWA_2.6.3_SeqWare_1.1.0-alpha.5
    # Do you want to install the workflows on the worker nodes? 
    install_workflow=true
    # Do you want to run HelloWorld as a test workflow once the worker node is set up?
    test_workflow=true
    # you can make new ones or change information in these blocks and use these blocks to launch a cluster
    [cluster1]
    number_of_nodes = 2
    target_directory = target-aws-1
    [singlenode1]
    number_of_nodes=1
    target_directory=target-aws-5

Then, run bindle like this:

    cd ~/architecture-setup/Bindle
    perl bin/launch-cluster.pl --config aws --custom-params singlenode1
    
Bindle will now begin the process of provisioning and setting up new VMs.

### Running youxia

Youxia is an application that can start up new VMs based on existing snapshots. It is also capable of taking advantage of Amazon Spot Pricing for the instances that it creates, and can also be used to tear down VMs, when necessary. You can learn more about youxia [here](https://github.com/CloudBindle/youxia#youxia).

**TODO: More info needed about using youxia in this context, further testing required.**

## Saving your work

If you have made some configuration changes within your docker container, you may find it useful to save those changes for your next session, when you exit the container. To do this, you can use docker's `commit` function:

    docker commit pancancer_launcher pancancer/pancancer_launcher:local-1.0.0
    
The next time you run the startup script, you can reconnect to your saved image like this:

    bash start_launcher_container.sh ~/.ssh/my_key.pem local-1.0.0
 
