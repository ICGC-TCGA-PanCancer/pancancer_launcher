# PanCancer Launcher

## Introduction

The pancancer_launcher docker container is a docker container that contains all of the nececssary infrastructure to create new pancancer worker nodes which can be used as workers, or as the basis of a new VM snapshot, and start up new VMs based on existing snapshots.  The launcher also contains our centralized "decider" client that lets you fetch new work to be done e.g. the donors which need to be processed with a given workflow at your site.

This document will guide you in installing and using this container.

#### Before you begin

Docker containers can be installed on any host machine capable of running docker. This document will assume that you are running on Amazon Web Services. 

If you are unfamiliar with docker, you might want to read about it [here](https://www.docker.com/whatisdocker/).

## Preparing the host machine

#### Installing Docker

Start up a new VM in AWS. This guide uses configuration that assumes you will be working in the AWS North Virginia region. You will want to use an Ubuntu 14.04 AMI, and give yourself at least 50 GB for storage space (docker images can take up a bit of space). An m3.large HVM instance type should do just fine.

**IMPORTANT:** Docker has specific requirements for the Linux kernel. For Ubuntu, the minimum kernel version supported is 3.10 (this minimum kernel version may vary with different Linux distributions). If your VMs do not have this kernel, you may need to consider upgrading. More information about docker and kernel requirements can be found [here](https://docs.docker.com/installation/ubuntulinux/).

When you instance has finished starting up, log in to it (this guide assumes you are logging in to the VM as the "ubuntu" user) and install docker. A detailed installation guide can be found [here](https://docs.docker.com/installation/), although installing docker on Ubuntu is quite simple; you can simply run this command:

    wget -qO- https://get.docker.com/ | sh

<!--
if future versions of docker are ever incompatible with our dockerfile, we may need to change the installation process to specify a specifc version of docker. Can probably figure it out by reading through their install script -->

Once you have docker installed, you will want to give your current user access to the "docker" group:

    sudo usermod -aG docker ubuntu

This will save you the trouble of having to "sudo" every docker command.

**You will need to log out of your host machine/VM and then log back in for this change above to take effect.**

**DO THIS NOW.**

To see if your docker installation is working correctly, you can run the "hello world" container:

    docker run hello-world

You should see the following if everything is working OK:

    Hello from Docker.
    This message shows that your installation appears to be working correctly.

*(If you have had any problems getting docker installed, you may wish to consult the [detailed installation guide](https://docs.docker.com/installation/))*

#### Installing the pancancer_launcher container

Once you have docker installed, pull the docker image:

    docker pull pancancer/pancancer_launcher

This command will pull the *latest* version of pancancer_launcher. If there is a specific version of the container you wish to pull, you can add the version to the command like this:

    docker pull pancancer/pancancer_launcher:1.0.0

To see further details about the container (such as the available versions/tags), see the [relevant dockerhub page](https://registry.hub.docker.com/u/pancancer/pancancer_launcher/).

#### Setting up your SSH pem keys.

The pancancer_launcher can start up new VMs on AWS. To do this, it needs access to the SSH pem key that you want to use for this purpose. Please make sure that you have copied your pem key to the host machine, and placed it in `~ubuntu/.ssh/<the name of your key>.pem`.  This is usually the SSH pem key you used to log in to the launcher host machine.  Make sure you `chmod 600 ~ubuntu/.ssh/<the name of your key>.pem` for security reasons.

## Starting the Launcher

The easiest way to start up the pancancer_launcher container is to use a helper script. You can get the helper script like this:

    wget https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/architecture-setup/3.0.0/start_launcher_container.sh
    
The script takes two arguments:
 - The path to the pem key that you want to use for new worker VMs
 - The version/tag of the container you wish to start.

<!-- There is a third argument, for ENVironment (AWS, OpenStack, local workstation, ...) and it is used to help the script determine the public IP address of the launcher node, but this won't be used until architecture 3. Also, that code is not yet fully tested. -->

Executing the script can look like this:

    bash start_launcher_container.sh ~/.ssh/<the name of your key>.pem latest
<!--
NOTE FOR SOLOMON: need to update sample for aws.cfg in pancancer-bag playbook and also set up folder for config, add notes about how to configure different workflows (Done: openstack.cfg not being copied for some reason). Better: Don't worry about copying in a config from host (for now), container should already container the configs that are ready to go (Done). Need to get mappings for Workflow -> instance type (for example, BWA needs m1.xlarge) (Done - need more details?). Also need list of up-to-date version strings for workflows (TODO!). Need newer AMI ID (Done). Delete all gluster stuff from config (Done). What does bwa_version_string do, can it be removed? (TODO!) Also, BWA should be 2.6.1. Change name of "cluster1" to "multinode" (Done). Also, clusters may not work so maybe remove that from the config.
Make sure Adam's latest changes are in the Bindle template.
Also: can the security group be passed in for AWS? 
Document sercurity groups! Add config in aws.cfg Also: Security group should have rule to SSH for public IP of launcher and worker in same group can communicate.
-->
This should start up your container.

| Docker Tip: |
--------------
| If you type "exit" when inside a container, it will shut down all processes, and you may lose your work. if you wish to leave the running container's shell, but you don't want to terminate everything, you can *detach* from the container by typing <kbd>Ctrl</kbd><kbd>P</kbd> <kbd>Ctrl</kbd><kbd>Q</kbd>. This will return you to your host machine's shell, but leave all of the processes in the container still running. To return to you your container, you can use the docker attach command: |
|`docker attach pancancer_launcher`|
|Docker also allows you to [pause](https://docs.docker.com/reference/commandline/cli/#pause) and [unpause](https://docs.docker.com/reference/commandline/cli/#unpause) running containers. |

## Using the Launcher

Once the container has started, you should have a fully functional launcher host that is capable of running Bindle to create new worker nodes, snapshot these nodes in environments that support this, run the decider client to generate workflow parameterization files (INIs) per donor, etc. We will cover the following processes in this guide below and link to more detailed guides as appropriate:

* start the launcher Docker container and login
* from the container, launch a new worker host on a cloud (AWS in our example here) which is capable of running the PanCancer workflows
* get a test job from the central decider
* run that test job of a workflow on the new worker host

### GNOS Pem keys
If you plan on running workflows that require a valid GNOS pem key, please ensure that your `gnos.pem` file is in `~/.ssh`. You will find there is a placeholder file already in that location, **but it is an empty placeholder!** You **must** overwrite the contents of this file with your real pem key file. This file will be copied over to your worker nodes so that they can run the workflows that require a GNOS pem key.

You are now ready to run Bindle to create a new VM as a first step.

## Running Bindle

Bindle is a toolset that can create new VMs, and install workflows and all of their necessary dependencies onto the VMs. You can learn more about Bindle [here](https://github.com/CloudBindle/Bindle#about-bindle).

If you wish to run Bindle, the first thing you will need to do is edit your Bindle configuration file. For AWS, this file is located at `~/.bindle/aws.cfg`.

### Editing your Bindle configuration file
You will need to edit this file before you run Bindle. The most important parts you will edit are related to Keys, Volumes, and Workflows.

#### Keys
The most important edits are setting the correct values for `aws_key`, `aws_secret_key`, `aws_ssh_key_name`, and `aws_ssh_pem_file` (which should reference the SSH pem file you copied into this container from your host).

#### Instance type
Some workflows run best with specific instance types. Here is a table with the best pairings, for AWS:

| Workflow | Instance Type |
|----------|---------------|
| BWA      | m1.xlarge     |
| Sanger   | r3.8xlarge    |
| DKFZ/EMBL| r3.8xlarge    |

<!-- TODO: Instance Type and Volumes can probably be combined in to one section -->


#### Volumes
You may also need to edit `aws_ebs_vols` and `lvm_device_whitelist`, depending on what AMI you are using. This sample config file uses an AMI that is launched as an m1.xlarge. It has 4 volumes so there are 4 block device mappings to ephemeral drives. If your AMI and instance type have a different number of volumes, you may need to adjust these values.

#### Workflows
You can configure which workflows you want to install on a worker. The `workflows` configuration value contains a list of actual workflow bundle names. `workflow_name` is a list of the simple names of the workflows. The example above illustrates installing *all* of the workflows, but you do not have to do this if you only intend to run one workflow. For example, to only run the BWA workflow, you can edit your configuration to look like this:

    workflow_name=BWA
    workflows=Workflow_Bundle_BWA_2.6.1_SeqWare_1.1.0-alpha.5

#### Security Group
In AWS, new nodes are launched in the "default" security group, unless you specify otherwise. If your default security group *does not* allow inbound connections from your launcher node, you can specify a security group in your config file for your worker nodes. You can configure your worker to be in the same security group as your launcher. For example, if your launcher's security group is "SecGrp1", you would add to your configuration file:

    aws_security_group=SecGrp1
    
You should also configure your security group so that it accepts incoming SSH connections from the public IP address of your launcher node.

### Provisioning worker nodes with Bindle

Once you have completed configuring Bindle, you can run bindle like this:

    cd ~/architecture-setup/Bindle
    perl bin/launch_cluster.pl --config aws --custom-params singlenode
    
Bindle will now begin the process of provisioning and setting up new VMs. Later on, you may want to read [this](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/feature/documentation_overhaul/production/fleet_management.md) page about managing a fleet of Pancancer VMs.

#### Verifying the new worker node.

The playbook that sets up the worker should complete with text that looks like this:

    PLAY RECAP ******************************************************************** 
    master                     : ok=60   changed=40   unreachable=0    failed=0   
    
*NOTE: The actual number of plays may vary, depending on how many workflows you installed*

To connect to your new worker node, execute the following commands:

    cd singlenode_vagrant_1/master
    vagrant ssh

**NOTE:** If you changed the value of `target_directory` in your configuration, the first command should look like this:

    cd <your value for target_directory>/master

Once you are connected to your worker, you can check which workflows are installed by examining the `/workflows` directory:

    ls -l /workflows
    
Output:

    total 56300
    -rw-r--r-- 1 root root 57636720 May 28 17:56 seqware-distribution-1.1.1-full.jar
    drwxr-xr-x 3 root root     4096 May 28 17:56 Workflow_Bundle_BWA_2.6.1_SeqWare_1.1.0-alpha.5
    drwxr-xr-x 3 root root     4096 May 28 18:01 Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.1
    
*NOTE: The output might vary depending on the number of workflows you configured to install*
    
You should see a directory for each workflow you configured in your installation.

If you want to see which docker images are installed on the worker, you can use this command:

    docker images
    
Output:

    REPOSITORY                              TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
    pancancer/seqware_whitestar_pancancer   1.1.1               ec5640650e0d        13 days ago         2.113 GB
    seqware/seqware_whitestar               1.1.1               25c37e8ca531        13 days ago         1.565 GB

*NOTE: This output may vary. For example, the value for "CREATED" is relative to the moment you run the command.*

You can then exit your worker by typing "exit". This will return you to the shell in the pancancer_launcher container on your launcher node.

#### Running multiple nodes

Once you have a configuration that has been used to successfully provision a node, you can update your configuration file with additional blocks for additional nodes, and then provision them as well. For a total of three nodes, you could set your configuration like this:

    [singlenode1]
    number_of_nodes=1
    target_directory=singlenode_vagrant_1
    
    [singlenode2]
    number_of_nodes=1
    target_directory=singlenode_vagrant_2
    
    [singlenode3]
    number_of_nodes=1
    target_directory=singlenode_vagrant_3

Provisioning these three nodes is quite simple:

    cd ~/architecture-setup/Bindle
    perl bin/launch_cluster.pl --config aws --custom-params singlenode1
    perl bin/launch_cluster.pl --config aws --custom-params singlenode2
    perl bin/launch_cluster.pl --config aws --custom-params singlenode3

<!--
## Running youxia

Youxia is an application that can start up new VMs based on existing snapshots. It is also capable of taking advantage of Amazon Spot Pricing for the instances that it creates, and can also be used to tear down VMs, when necessary. You can learn more about youxia [here](https://github.com/CloudBindle/youxia#youxia).

**TODO: More info needed about using youxia in this context, further testing required.**
-->
## Running a workflow

### Login to worker

In the steps above we created a worker node that has all the workflows installed and ready to go, in this example BWA and HelloWorld.  The next step in your testing is to login to the worker node and try out the HelloWorld workflow to ensure the worker node is OK.

Log into your worker node now, you can use the "connect" button in the AWS console to get information on how to connect via SSH.

### Using Docker to run a workflow

Workflows are run by calling docker and executing the workflow using a seqware container. To run the HelloWorld workflow, the command looks like this:

    docker run --rm -h master -t -v /var/run/docker.sock:/var/run/docker.sock \
      -v /datastore:/datastore \
      -v /workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.1:/workflow \
      -i pancancer/seqware_whitestar_pancancer:1.1.1 \
      seqware bundle launch --dir /workflow --no-metadata

If you execute this command, you should see the output of the HelloWorld workflow indicate a successful run, look for:

    ...
    [2015/05/28 17:23:18] | Setting workflow-run status to completed for: 10
    [--plugin, io.seqware.pipeline.plugins.WorkflowWatcher, --, --workflow-run-accession, 10]
    Workflow run 10 is currently completed
    ...

The key to this is mapping the HelloWorld bundle directory (`/workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.1`) to a specific directory within the container (`/workflow`), and then telling Docker to run the `seqware` command with the parameters `bundle launch --dir /workflow --no-metadata`. The `--dir /workflow` parameter tells seqware that the workflow to execute is in the `/workflow` directory, which was mapped to `/workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.1` on the host.

To change which workflow that you are executing, change the mapping of the container's `/workflow` directory in the command above, like this:
    
    docker run...
      ...
      -v /workflows/Workflow_Bundle_BWA_2.6.1_SeqWare_1.1.0-alpha.5:/workflow \
      ...

TODO: More detail, other workflow examples...

### Using INI files from the Central Decider Client
<!-- TODO: Relative links should be used here, but for now we are pointing at a document that only exists on a branch so I don't think relative links work for that case -->
When running your workflows, you will probably want to use an INI file generated by the Central Decider Client. Please [click here](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/feature/documentation_overhaul/production/central_decider_client.md) for more information on how to get the INI files and how they can be submitted to a worker node.

<!--
## Saving your work

If you have made some configuration changes within your docker container, you may find it useful to save those changes for your next session, when you exit the container. To do this, you can use docker's `commit` function:

    docker commit pancancer_launcher pancancer/pancancer_launcher:local-1.0.0
    
The next time you run the startup script, you can reconnect to your saved image like this:

    bash start_launcher_container.sh ~/.ssh/my_key.pem local-1.0.0
-->
