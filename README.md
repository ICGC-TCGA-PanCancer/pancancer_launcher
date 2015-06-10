# PanCancer Launcher

## Introduction

The pancancer\_launcher docker container is a docker container that contains all of the nececssary infrastructure to create new pancancer worker nodes which can be used as workers, or as the basis of a new VM snapshot, and start up new VMs based on existing snapshots.  The launcher also contains our centralized "decider" client that lets you fetch new work to be done e.g. the donors which need to be processed with a given workflow at your site.

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


Once you have docker installed, you will want to give your current user access to the "docker" group:

    sudo usermod -aG docker ubuntu

This will save you the trouble of having to "sudo" every docker command.

**You will need to log out of your host machine/VM and then log back in for this change above to take effect.**

**DO THIS NOW.**

*NOTE:* To use docker properly, your network must allow your host machine to connect to dockerhub on the internet, as well as the hosts that provide dockerhub's storage for images. If you are behind proxies, you must configure them to allow your launcher to have access to these outside networks, or docker will not be able to pull in new images from dockerhub.

To see if your docker installation is working correctly, you can run the "hello world" container:

    docker run hello-world

You should see the following if everything is working OK:

    Hello from Docker.
    This message shows that your installation appears to be working correctly.

*(If you have had any problems getting docker installed, you may wish to consult the [detailed installation guide](https://docs.docker.com/installation/))*

#### Installing the pancancer\_launcher container

Once you have docker installed, pull the docker image:

    docker pull pancancer/pancancer_launcher

This command will pull the *latest* version of pancancer\_launcher. If there is a specific version of the container you wish to pull, you can add the version to the command like this:

    docker pull pancancer/pancancer_launcher:1.0.0

To see further details about the container (such as the available versions/tags), see the [relevant dockerhub page](https://registry.hub.docker.com/u/pancancer/pancancer_launcher/).

### Credentials
The pancancer\_launcher container will require several sets of credentials:
 - SSH key - this is the key that you use to launch new VMs in your environment. Your SSH keys should be in `~/.ssh/` on your host machine.
 - GNOS keys - these keys are used by some workflows. Your GNOS keys should be placed in `~/.gnos` on your host machine. If you have a *single* GNOS key we recommend you put it in `~/.gnos/gnos.pem` since the directions below reference that by default. If you have multiple GNOS keys, you should still place them in `~/.gnos/`, although your workflow configuration will need to be altered to reference the different keys correctly. All files in `~/.gnos` on the host VM will be copied into your container.
 - AWS credentials - your AWS credentials are needed to download certain workflows. Your AWS credentials should be placed in your `~/.aws` directory. Please use the `~/.aws/config` filename format. If you have ever used the AWS CLI tool, you probably already have these files in place and you can just copy them to the host machine. If you do not have these files set up, follow thes instructions on [this page](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files). All files in your `~/.aws` directory on the host VM will be copied into the container.

**IMPORTANT:** Your AWS credentials are private! Do **not** create an AMI/snapshot of any VM with valid AWS credentials on it! Remove the credentials before creating any AMI/snapshot.

#### Setting up your SSH pem keys.

The pancancer\_launcher can start up new VMs on AWS. To do this, it needs access to the SSH pem key that you want to use for this purpose. Please make sure that you have copied your pem key to the host machine, and placed it in `~ubuntu/.ssh/<the name of your key>.pem`.  This is usually the SSH pem key you used to log in to the launcher host machine.  Make sure you `chmod 600 ~ubuntu/.ssh/<the name of your key>.pem` for security reasons.

## Starting the Launcher

The easiest way to start up the pancancer\_launcher container is to use a helper script. You can get the helper script like this:

    wget https://github.com/ICGC-TCGA-PanCancer/pancancer_launcher/releases/download/3.0.4/start_launcher_container.sh
    
The script takes two arguments:
 - The path to the pem key that you want to use for new worker VMs
 - The version/tag of the container you wish to start.

Now would be an excellent time to start a screen session to make it easier to disconnect and reconnect your SSH session later without interrupting the Docker container.

    # for more information
    man screen

Executing the script can look like this:

    bash start_launcher_container.sh ~/.ssh/<the name of your key>.pem latest

For example, when launching the tagged 3.0.3 release use 

    bash start_launcher_container.sh ~/.ssh/<the name of your key>.pem 3.0.3

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

### GNOS keys
If you plan on running workflows that require a valid GNOS key, please follow these steps:

1. Inside the launcher container, create the directory `~/.gnos`
2. Copy all of your GNOS keys into this directory.

All of the files in your launcher container's `~/.gnos` should be copied into `~/.gnos` *on the worker.*

## Running Bindle

Bindle is a toolset that can create new VMs, and install workflows and all of their necessary dependencies onto the VMs. You can learn more about Bindle [here](https://github.com/CloudBindle/Bindle#about-bindle).

If you wish to run Bindle, the first thing you will need to do is edit your Bindle configuration file. For AWS, this file is located at `~/.bindle/aws.cfg`.

### Editing your Bindle configuration file
You will need to edit this file before you run Bindle. The most important parts you will edit are related to Keys, Volumes, and Workflows.

#### Keys
The most important edits are setting the correct values for `aws_key`, `aws_secret_key`, `aws_ssh_key_name`, and `aws_ssh_pem_file` (which should reference the SSH pem file you copied into this container from your host).

#### Region

The config file is setup for the North Virginia region in AWS.  If you are working in a different region you need to customize `aws_region` (see the API docs for the possible values) and you need to make sure the `aws_image` is valid for this region.

#### Instance type
Some workflows run best with specific instance types. Here is a table with the best pairings, for AWS in Virginia:

| Workflow | Instance Type | AMI         | Device mapping (as a line in your aws.cfg file)
|----------|---------------|-------------|-------------------
| BWA      | m1.xlarge     | ami-d85e75b0|aws_ebs_vols = "aws.block_device_mapping = [{'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize'=>100  },{ 'DeviceName' => '/dev/sdb', 'VirtualName' => 'ephemeral0'},{'DeviceName' => '/dev/sdc','VirtualName' => 'ephemeral1'},{'DeviceName' => '/dev/sdd', 'VirtualName'=>'ephemeral2'},{'DeviceName' => '/dev/sde', 'VirtualName' => 'ephemeral3'}]"
| Sanger   | r3.8xlarge    | ami-d05e75b8|aws_ebs_vols = "aws.block_device_mapping = [{'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize'=>100  },{'DeviceName' => '/dev/sdb', 'Ebs.VolumeSize'=>400  },{ 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral0'},{'DeviceName' => '/dev/sdd','VirtualName' => 'ephemeral1'}]"
| DKFZ/EMBL| r3.8xlarge    | ami-d05e75b8|aws_ebs_vols = "aws.block_device_mapping = [{'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize'=>100  },{'DeviceName' => '/dev/sdb', 'Ebs.VolumeSize'=>400  },{ 'DeviceName' => '/dev/sdc', 'VirtualName' => 'ephemeral0'},{'DeviceName' => '/dev/sdd','VirtualName' => 'ephemeral1'}]"


#### Volumes
You may also need to edit `aws_ebs_vols` and `lvm_device_whitelist`, depending on what AMI you are using. This sample config file uses an AMI that is launched as an m1.xlarge. It has 4 volumes so there are 4 block device mappings to ephemeral drives. If your AMI and instance type have a different number of volumes, you may need to adjust these values.

#### Workflows
You can configure which workflows you want to install on a worker. The `workflows` configuration value contains a list of actual workflow bundle names. `workflow_name` is a list of the simple names of the workflows. The example above illustrates installing *all* of the workflows, but you do not have to do this if you only intend to run one workflow. For example, to only run the BWA workflow, you can edit your configuration to look like this:

    workflow_name=BWA
    workflows=Workflow_Bundle_BWA_2.6.1_SeqWare_1.1.0-alpha.5

#### Security Group
In AWS, new nodes are launched in the "default" security group, unless you specify otherwise. If your default security group *does not* allow inbound connections from your launcher node, you can specify a security group in your config file for your worker nodes. You can configure your worker to be in the same security group as your launcher. For example, if your launcher's security group is "SecGrp1", you would add to your configuration file:

    aws_security_group=SecGrp1
    
**VERY IMPORTANT:** _You should also configure your security group so that it accepts incoming SSH and TCP connections from the public IP address of your launcher node, as well as from the security group itself._
_It is also a good idea to ensure that your security group is not open to the whole Internet in general - you should only allow inbound connections from known IP address on specific ports whenever possible._

### Provisioning worker nodes with Bindle

Once you have completed configuring Bindle, you can run bindle like this:

    cd ~/architecture-setup/Bindle
    perl bin/launch_cluster.pl --config aws --custom-params singlenode
    
    
Bindle will now begin the process of provisioning and setting up new VMs. Later on, you may want to read [this](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/3.0.3/production/fleet_management.md#managing-an-existing-pancancer-environment) page about managing a fleet of Pancancer VMs.

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

You can then exit your worker by typing "exit". This will return you to the shell in the pancancer\_launcher container on your launcher node.

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

#### Snapshotting a Worker for Arch3 Deployment 

At this point, you should have a worker which can be used to take a snapshot in order to jumpstart future deployments. The steps to take here differ a bit between environments

1. First, clean up the architecture 3 components so that you can cleanly upgrade between versions. Login to the worker host and from the home directory delete bash scripts that start the worker, the jar file for our tools, the lock file that the worker may have generated, and the log file as well. The full set of locations is:
    * everything in /home/ubuntu
    * /var/log/arch3\_worker.log
    * /var/run/arch3\_worker.pid
1. In AWS, create an AMI based on your instance. Make sure to specify the ephemeral disks that you wish to use, arch3 will provision a number of ephemeral drives that makes what you specify in your snapshot.
1. In OpenStack, create a snapshot based on your instance. 
1. When setting up arch3 (see below), you may now specify the image to use in your ~/.youxia/config file


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



### Using INI files from the Central Decider Client

When running your workflows, you will probably want to use an INI file generated by the Central Decider Client. Please [click here](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/3.0.3/production/central_decider_client.md#the-central-decider-client) for more information on how to get the INI files and how they can be submitted to a worker node.

### Using the Queue-based Scheduling System

If instructed to, you may be able to use our queue-based scheduling system. This is pre-installed into the launcher and should only need some configuration to provision workers, tear-down workers, and schedule workflows to workers. 

For debugging, you can login to the RabbitMQ web interface at port 15672 or login to postgres using "psql -U queue_status".

For certain pancancer launcher versions, you'll need to create the sql schema:

    PGPASSWORD=queue psql -h 127.0.0.1 -U queue_user -w queue_status < /home/ubuntu/arch3/dbsetup/schema.sql

First, you'll want to correct your parameters used by the container\_host playbook to setup workers. For more information, the parameters here are those for the [container host bag](https://github.com/ICGC-TCGA-PanCancer/container-host-bag):

    vim ~/params.json
    
Notable parameters: Specify for queueHost, the internal ip address of your launcher. 
    
Second, you'll want to correct your parameters for arch3 for your environment:

    vim ~/arch3/config/masterConfig.json

Notable parameters: To turn off reaping functionality, add the parameter "youxia\_reaper\_parameters" with a value of "--test". For use in an OpenStack environment, add "--openstack" as a parameter to the deployer and the reaper. 

Third, you'll want to correct your parameters used for youxia (see [this](https://github.com/CloudBindle/youxia#configuration))

    vim ~/.youxia/config

Notable parameters: Specify the private ip address under sensu\_ip\_address, we are currently using ami-d56111a2

You will then be able to kick-off the various services:

    screen
    java -cp ~/arch3/bin/pancancer-arch-3-*.jar info.pancancer.arch3.jobGenerator.JobGenerator --config ~/arch3/config/masterConfig.json --total-jobs 5
    (create a new window)
    java -cp ~/arch3/bin/pancancer-arch-*.jar info.pancancer.arch3.coordinator.Coordinator  --config ~/arch3/config/masterConfig.json --endless
    (create a new window)
     java -cp ~/arch3/bin/pancancer-arch-3-*.jar info.pancancer.arch3.containerProvisioner.ContainerProvisionerThreads  --config ~/arch3/config/masterConfig.json --endless
    

See [arch3](https://github.com/CancerCollaboratory/sandbox/blob/develop/pancancer-arch-3/README.md#testing-locally) for more details. 

### Monitoring
The pancancer_launcher contains uses sensu for monitoring its worker nodes. It also contains Uchiwa, which functions as a dashboard for the senus monitoring. 

To access the dashboard, navigate to 

    http://<public IP of machine running pancancer_launcher>:3000/
    
You will be prompted for a username and password. Enter: "seqware" and "seqware". You will then be able to see the status of the worker nodes, and the sensu-server itself.

**IMPORTANT:** On AWS, you may have to edit your security group rules to allow inbound traffic to port 3000 for the IP address of your launcher host VM if you want to be able to see the Uchiwa dashboard. You should also ensure that your security group allows all inbound TCP connections from itself and all inbound SSH connections from itself, as well as all TCP and SSH inbound connections from the public IP address of the launcher host VM.

## Saving your work

The restart policy of the pancancer_launcher should be to restart automatically if you accidentally exit the container. Running processes may be terminated on exit, but the filesystem of your container should be preserved. If you want to persist your configuration outside of the container, you can use the read-write mounted host volume. Inside the container, this volume exists as `/opt/from_host/config`. Outside the container, it exists as `~/pancancer_launcher_config`. To preserve your configuration, you can use these simple commands inside the container:

    cp -a ~/.bindle /opt/from_host/config/
    cp -a ~/.youxia /opt/from_host/config/
    cp -a ~/arch3/config /opt/from_host/config/
    
Outside the container (You can *detach* from a running container using <kbd>Ctrl</kbd><kbd>P</kbd> <kbd>Ctrl</kbd><kbd>Q</kbd>, and then use `docker attach pancancer_launcher` to re-attach later), you should be able to see the copied configuration files:

    ls -la ~/pancancer_launcher_config/
    drwxr-xr-x  2 ubuntu ubuntu 4096 Jun 10 15:51 .bindle
    drwxr-xr-x  2 ubuntu ubuntu 4096 Jun 10 14:22 config
    drwxr-xr-x  2 ubuntu ubuntu 4096 Jun 10 14:22 .youxia

When you are installing a new version of the pancancer\_launcher container, you can import these files into a new container by copying in from `/opt/from_host/config`, for example:

    cp -a /opt/from_host/config/.youxia/ ~

## Known Issues
### Issues related to installing Docker
Sometimes the docker install process will hang. This usually happens when it tries to apply a kernel update. One workaround for this is to execute these commands and then install docker:

    sudo apt-get install linux-image-extra-$(uname -r)
    sudo modprobe aufs

It might be necessary to simply terminate a launcher host whose docker installation gets stuck at this point, and then start a new one and run these commands *before* attempting to install docker.

### Issues related to networking

#### Proxies
If your launcher host is behind proxies, make sure that they will allow this host to connect to dockerhub to download the docker images. Dockerhub may also store docker redirect a "docker pull" request to their main storage servers, so ensure that your proxies allow access to those servers as well.
