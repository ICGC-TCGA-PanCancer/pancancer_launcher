# PanCancer Launcher

## Introduction

The pancancer\_launcher docker container consists of all of the necessary infrastructure to create new pancancer worker nodes,  snapshot them, and dynamically scale a fleet of worker VMs based on these snapshots.  The launcher also contains our centralized "decider" client that lets you fetch new work to be done for the core PanCancer workflows e.g. the donors which need to be processed with a given workflow at your site.

This document will guide you in installing and using this container in AWS but these directions will be applicable to all cloud environments.

You will find additional tips and tricks for specific PanCancer cloud environments at [site-specific docs](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/develop/production/site-specific/README.md)

### Intended audience
The following guide is intended for developers and users seeking a deeper understanding of the PanCancer Launcher.

Most other users should read the [Quick Start guide for the Pancancer Command Line Interface (Pancancer CLI)](https://github.com/ICGC-TCGA-PanCancer/cli/blob/0.0.1/QuickStart.md). The Pancancer CLI is tool that offers a simple and easy-to-use interface to the Pancancer tools.

#### Before you begin

Docker containers can be installed on any host machine capable of running docker. This document will assume that you are running a VM on Amazon Web Services for this purpose.  Please see the [AWS](http://aws.amazon.com) for more information.

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

For software developers working on the launcher, once you have docker installed, pull the docker image:

    docker pull pancancer/pancancer_launcher

This command will pull the *latest* version of pancancer\_launcher.

For cloud shepherds trying to run workflows, if there is a specific version of the container you wish to pull, you can add the version to the command like this:

    docker pull pancancer/pancancer_launcher:3.1.5

To see further details about the container (such as the available versions/tags), see the [relevant dockerhub page](https://hub.docker.com/r/pancancer/pancancer_launcher/).

### Credentials
The pancancer\_launcher container will require several sets of credentials:
 - SSH key - this is the key that you use to launch new VMs in your environment. Your SSH keys should be in `~/.ssh/` on your host machine.
 - GNOS keys - these keys are used by some workflows. Your GNOS keys should be placed in `~/.gnos` on your host machine. If you have a *single* GNOS key we recommend you put it in `~/.gnos/gnos.pem` since the directions below reference that by default. If you have multiple GNOS keys, you should still place them in `~/.gnos/`, although your workflow configuration will need to be altered to reference the different keys correctly. All files in `~/.gnos` on the host VM will be copied into your container.
 - AWS credentials - your AWS credentials are needed to download certain workflows. Your AWS credentials should be placed in your `~/.aws` directory. Please use the `~/.aws/config` filename format. If you have ever used the AWS CLI tool, you probably already have these files in place and you can just copy them to the host machine. If you do not have these files set up, follow thes instructions on [this page](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-config-files). All files in your `~/.aws` directory on the host VM will be copied into the container.

**IMPORTANT:** Your AWS credentials are private! Do **not** create an AMI/snapshot of any VM with valid AWS credentials on it! Remove the credentials before creating any AMI/snapshot.

#### Setting up your SSH pem keys.

The pancancer\_launcher can start up new VMs on AWS. To do this, it needs access to the SSH pem key that you want to use for this purpose. Please make sure that you have copied your pem key to the host machine, and placed it in `~ubuntu/.ssh/<the name of your key>.pem`.  This is usually the SSH pem key you used to log in to the launcher host machine.  Make sure you `chmod 600 ~ubuntu/.ssh/<the name of your key>.pem` for security reasons.

## Using the Launcher

Once the container has started, you should have a fully functional launcher host that is capable of running the Deployer to create new worker nodes, snapshot these nodes in environments that support this, run the decider client to generate workflow parameterization files (INIs) per donor, etc. We will cover the following processes in this guide below and link to more detailed guides as appropriate:

* start the launcher Docker container and login
* from the container, launch a new worker host on a cloud (AWS in our example here) which is capable of running the PanCancer workflows
* get a test job from the central decider
* run that test job of a workflow on the new worker host

<!--
If you are unable to use the queue-based scheduler, please navigate to the section about [running Bindle](#running-bindle)
-->

### Starting the Launcher

The easiest way to start up the pancancer\_launcher container is to use a helper script. You can get the helper script like this:

    wget https://github.com/ICGC-TCGA-PanCancer/pancancer_launcher/releases/download/3.1.5/start_launcher_container.sh

The script takes two arguments:
 - The path to the pem key that you want to use for new worker VMs
 - The version/tag of the container you wish to start.

Now would be an excellent time to start a screen session to make it easier to disconnect and reconnect your SSH session later without interrupting the Docker container.

    # for more information
    man screen

Executing the script can look like this (recommended for developers):

    bash start_launcher_container.sh -p ~/.ssh/<the name of your key>.pem -i latest

For example for cloud shepherds, when launching the tagged 3.1.5 release use:

    bash start_launcher_container.sh -p ~/.ssh/<the name of your key>.pem -i 3.1.5 -f MyFleet

The full list of options for the script is:

      -p, --pem_key - The path to the pem key file you want to use to start up new workers.
      -i, --image_version - The version of pancancer_launcher you want to run.
      -e, --host_env - The host environment you are running in (Either "AWS" or "OPENSTACK"). If you do not specify a value, "AWS" will be defaulted.
      -t, --test_mode - Run in test mode (lauches workers immediately when container starts). Defaults to "false"
      -f, --fleet_name - The name of the fleet of workers that will be managed by this launcher. If you do not specify one, a random name will be generated.
      --target_env - Only used when running in test mode.
      -h, --help - Prints this message.

This should start up your container.

#### Working with a docker container

The `start_launcher_container.sh` script starts the container with a restart policy so that the docker service will restart your container automatically, if you accidentally exit the container. Ideally, all of your files will be preserved if you exit a container, but any running processes will be halted until the container restarts.

If you wish to leave the running container's shell, but you *do not* want to terminate/restart everything, you can *detach* from the container by typing <kbd>Ctrl</kbd><kbd>P</kbd> <kbd>Ctrl</kbd><kbd>Q</kbd>. This will return you to your host machine's shell, but leave all of the processes in the container still running. To return to you your container, you can use the docker attach command:

    docker attach pancancer_launcher
Docker also allows you to [pause](https://docs.docker.com/reference/commandline/cli/#pause) and [unpause](https://docs.docker.com/reference/commandline/cli/#unpause) running containers.

If you really need to halt a container, you must exit, and then you can use the `docker kill <container name or ID>`. The restart policy will not take effect if the container is stopped in this way.

### Using the Youxia Deployer and the Queue-based Scheduling System

Launching new workers can be done by the main architecture3 components, but you may need to create an initial snapshot to use when creating new images. Youxia is a component that can launch new VMs in AWS, OpenStack, and Azure. Once launched, they can be snapshotted for future use. Using snapshots speeds up the process of provisioning future worker nodes.

####Architecture3 components
The important components of Architecture3 are:

 - Generator - This program will generate job orders.
 - Coordinator - This program will coordinate the scheduling of job orders. It will read the job orders created by the Generator and create requests for VMs, if necessary, and also populate a job queue that Workers will read from.
 - Provisioner - This program will create VMs as necessary, based on the jobs in the job queue and specified size of the fleet.
 - Reaper - This program will detroy VMs. Normally it is called automatically when a VM has finished its work and is no longer needed, but it can also be called manually to clean up Worker VMs that are causing problems.
 - Deployer - This program will deploy an new VM and run a specified ansible playbook on it. Normally, this is called automatically by the Proivisioner, but it can be called manually to create a single worker VM. This is normally done to create a snapshot of a configured worker.

####Configuration
#####params.json
You will want to update your parameters used by the container\_host playbook to setup workers. For more information, the parameters here are those for the [container host bag](https://github.com/ICGC-TCGA-PanCancer/container-host-bag):

    vim ~/params.json

Here is an example of the `params.json`:

    {
      "SENSU_SERVER_IP_ADDRESS": "10.0.26.25",
      "aws_key": "<AWS KEY>",
      "aws_secret_key": "<AWS SECRET KEY>",
      "seqware_version": "1.1.1",
      "workflow_name": "HelloWorld",
      "http_workflows": {
        "DEWrapper": {
          "name": "Workflow_Bundle_DEWrapperWorkflow_1.0.2_SeqWare_1.1.0",
          "url": "http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_DEWrapperWorkflow_1.0.2_SeqWare_1.1.0.zip"
        },
        "HelloWorld": {
          "name": "Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0",
          "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0.zip"
        }
      },
      "s3_workflows": {
        "S3Workflow": {
          "name":"Workflow_Bundle_OnlyAvailableFromS3_1.0_SeqWare_1.1.0",
          "url":"s3://some.private.bucket/Workflow_Bundle_OnlyAvailableFromS3_1.0_SeqWare_1.1.0.zip"
        }
      },
      "containers": {
        "seqware_whitestar": {
          "name": "seqware_whitestar",
          "image_name": "seqware/seqware_whitestar:{{ seqware_version }}"
        },
        "pcawg-delly-workflow": {
          "name":"pcawg-delly-workflow",
          "image_name": "pancancer/pcawg-delly-workflow:1.0"
        },
        "pancancer_upload_download": {
          "name": "pancancer_upload_download",
          "image_name": "pancancer/pancancer_upload_download:1.1"
        }
      },
      "s3_containers": {
        "some_s3_container": {
          "name": "some_s3_container_1.2.3",
          "url": "s3://private.container.bucket/some_s3_container_1.2.3.tar"
        }
      },
      "http_containers": {
        "some_other_container": {
          "name":"some_other_container",
          "url":"http://www.some-other-organization.com/some_other_container.tar"
        }
      },
      "install_workflow": "true",
      "test_workflow": "true",
      "queueHost": "10.0.26.25",
      "queueName": "pancancer_arch_3",
      "lvm_device_whitelist": "/dev/xvdb,/dev/xvdc,/dev/xvdd,/dev/xvde",
      "single_node_lvm": true,
      "pancancer_arch3_version": "1.1-alpha.5",
      "seqware_engine":"whitestar-parallel",
      "seqware_use_custom_settings":false,
      "azure": false
    }

Important parameters to take note of:

 - SENSU_SERVER_IP_ADDRESS - This is the IP address of the sensu server. Normally, this is the same IP address of the launcher host. This IP address must be accessible to the worker. **IMPORTANT:** If your host machine ever restarts, you may need to reset this value to the host machine's new private IP address.
 - aws_key - This is your AWS Key. You don't need to fill this in if you are working on OpenStack
 - aws_secret_key - This is your AWS secret key. You don't need to fill this in if you are working on OpenStack.
 - workflows - This is a hash of workflows that you want to install onto workers. Workflows can come from a either a publicly accessible URL (usually over HTTP) or possibly from a private S3 bucket. The example above shows both. A simpler example that only installs the HelloWorld and DEWrapper workflow might look like this:
         ...
         "http_workflows": {
           "HelloWorld": {
             "name": "Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0",
             "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0.zip"
           },
         }
         ...

  An example of installing several workflows from publicy accessible URLs would look like this:

        ...
        "http_workflows": {
          "HelloWorld": {
            "name": "Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0",
            "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0.zip"
          },
          "BWA": {
            "name": "Workflow_Bundle_BWA-2.6.5_SeqWare_1.1.0",
            "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_BWA_2.6.5-SNAPSHOT_SeqWare_1.1.0.zip"
          },
          "Sanger": {
            "name": "Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_1.0.7_SeqWare_1.1.0",
            "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_1.0.7_SeqWare_1.1.0.zip"
          },
          "DEWrapper": {
            "name": "Workflow_Bundle_DEWrapperWorkflow_1.0.2_SeqWare_1.1.0",
            "url":"http://s3.amazonaws.com/oicr.workflow.bundles/released-bundles/Workflow_Bundle_DEWrapperWorkflow_1.0.2_SeqWare_1.1.0.zip"
          }
        },
        ...
 - containers - Much like workflows, you can specify any Docker containers that will need to be installed on the workers. Docker containers that are available via Dockerhub can be specified in the "containers" section. If the containers you wish to use are available as tar files on S3 or some other website, you can specify them in the "s3\_containers" or "http\_containers" sections.
 - queueHost - This is the IP address of the host machine where pancancer_launcher is running. This IP address must be accessible to the worker. **IMPORTANT:** If your host machine ever restarts, you may need to reset this value to the host machine's new private IP address.
 - single\_node\_lvm - If you plan to make use of the lvm options, ensure that your base image has the correct volumes attached to it. See the section on [Base AMI](#base-ami) for more info.
 - lvm\_device\_whitelist - If you are using lvm (set `"single\_node\_lvn":true`) you will need to specify the devices that you want to be used by lvm here.
 - azure - If you plan on using Azure, switch this to true

#####masterConfig.ini
You will also want to configure your parameters for arch3 for your environment:

    vim ~/arch3/config/masterConfig.ini

This file is used by architecture3 components such as the Generator, the Coordinator, the Provisioner, and the Reporter.

Notable parameters: To turn off reaping functionality, add the parameter "youxia\_reaper\_parameters" with a value of "--test", for example:

    [provision]
    max_running_containers=1
    youxia_deployer_parameters=--max-spot-price 0.001 --batch-size 3 --ansible-playbook /home/ubuntu/architecture-setup/container-host-bag/install.yml  -e /home/ubuntu/params.json
    youxia_reaper_parameters=--test

It is sometimes useful to have tags attached to new instances. To do this, you can create a new tags file named `server-tags.json`, like this:

    {
      "MY_TAG":"SOME_VALUE",
      "MY_OTHER_TAG":"SOME_OTHER_VALUE"
    }

Then, reference this tags file in the `masterConfig.ini` file:

    [provision]
    max_running_containers=1
    youxia_deployer_parameters=--max-spot-price 0.001 --batch-size 3 --ansible-playbook /home/ubuntu/architecture-setup/container-host-bag/install.yml -e /home/ubuntu/params.json --server-tag-file server-tags.json

For use in an OpenStack environment, add "--openstack" as a parameter to the deployer and the reaper. Use the "--azure" for that environment:

    [provision]
    max_running_containers=1
    youxia_deployer_parameters=--max-spot-price 0.001 --batch-size 3 --ansible-playbook /home/ubuntu/architecture-setup/container-host-bag/install.yml  -e /home/ubuntu/params.json --openstack
    youxia_reaper_params=--test --openstack

#####youxia config
Youxia will need to be configured so that it can deploy new worker nodes. The youxia configuration file is located at `~/.youxia/config`. An example of this file looks like this:

    [youxia]
    sensu_username = admin
    sensu_password = seqware
    sensu_ip_address = localhost
    sensu_port = 4567
    managed_tag = your_fleet_tag_name
    #slack_webhook = <slack RSS handler>

    # aws settings
    aws_ssh_key =/home/ubuntu/.ssh/<your key name>.pem
    aws_key_name = <your key name>
    region = us-east-1
    # to specify multiple zones, use a comma-separated list
    # we will target the zone with the cheapest spot price first
    zone = us-east-1a,us-east-1b,us-east-1c,us-east-1d,us-east-1e
    # openstack settings
    openstack_username = <tenant>:<username>
    openstack_password = <password>
    openstack_endpoint = http://10.5.73.21:5000/v2.0
    openstack_key_name = <key name on OpenStack>
    openstack_ssh_key = <path to SSH key>
    openstack_region = <region>
    # openstack_zone = <zone>

    [deployer]
    ami_image = <base image id>
    instance_type = m1.xlarge
    security_group = default
    product = Linux/UNIX
    # disable this for integration with pancancer_launcher
    disable_sensu_server = true

    [deployer_openstack]
    flavor = m1.xlarge
    min_cores = 4
    min_ram = 16384
    image_id = <base image id>
    security_group = default
    network_id = <network id>
    arbitrary_wait = 200000

    [seqware]
    rest_user = admin@admin.com
    rest_pass = admin
    rest_port = 8080
    rest_root = SeqWareWebService

    [generator]
    max_scheduled_workflows = 1
    max_workflows = 1
    workflow_accession = 1
    workflow_name = HelloWorld
    workflow_version = 1.0-SNAPSHOT

This file contains settings for both OpenStack, Azure, and AWS. You will only need to fill out the fields that are relevant for your specific cloud environment.
    vim ~/.youxia/config

For details about youxia configuration, see [here](https://github.com/CloudBindle/youxia#configuration).

Some of the more important parameters are for the sensu server IP address, and for the AMI/Image ID.

######Base AMI
You may need to create a new base image to launch workers in AWS. Default images available typically do not have a large enough root partition to install all of the workflows. It is recommended that you create a new custom base image which will a large root partition (250 GB should be enough) and some ephemeral drives, if you want to use them with the lvm settings in the `params.json` file.

#### Snapshotting a Worker for Arch3 Deployment

You can use the Youxia Deployer to launch a worker node that can be snapshotted (add --azure or --openstack in those environments). The command to do this is:

    cd ~/arch3
    Deployer  --ansible-playbook ~/architecture-setup/container-host-bag/install.yml --max-spot-price 1 --batch-size 1 --total-nodes-num 1 -e ~/params.json

If, for whatever reason, the Deployer fails to complete the setup of the instance, you may have to use the [Reaper](https://github.com/CloudBindle/youxia#reaper) to destroy it before trying again. To use the Reaper to destroy a specific node or nodes:

1. Create a file named "kill\_list.json" and populate it with a list of the nodes that need to be destroyed, like this:

        [
            "54.0.0.0",
            "54.0.0.1"
        ]

2. Call the Reaper using the `--kill-list` option:


        Reaper --kill-list kill-list.json

If all went well, at this point you should have a worker which can be used to take a snapshot in order to jumpstart future deployments. To allow for easier migration to newer arch3 versions, you should also clean arch3 components from that worker.

1. First, clean up the architecture 3 components so that you can cleanly upgrade between versions. Login to the worker host and from the home directory delete bash scripts that start the worker, the jar file for our tools, the lock file that the worker may have generated, and the log file as well. The full set of locations is:
    * all scripts, jars and json files in /home/ubuntu
    * /var/log/arch3\_worker.log
    * /var/run/arch3\_worker.pid
1. In AWS, create an AMI based on your instance. Make sure to specify the ephemeral disks that you wish to use, arch3 will provision a number of ephemeral drives that makes what you specify in your snapshot.
1. In OpenStack, create a snapshot based on your instance.
1. In Azure, attach disks to an Azure virtual machine if you wish to accomplish a similar task to that in AWS.
1. When setting up youxia for arch3 (see [above](#youxia-config)), you may now specify the id for that image to use in your ~/.youxia/config file

#### Basic testing
A basic test to ensure that everything is set up correctly is to run the queue and execute the HelloWorld workflow as a job. To generate the job, you can do this:

    Generator --workflow-name HelloWorld --workflow-version 1.0-SNAPSHOT --workflow-path /workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0 --config ~/arch3/config/masterConfig.ini --total-jobs 1

If you log in to the rabbitMQ console on your launcher (`http://<your launcher's IP address>:15672`, username: queue\_user, password: queue, unless you've changed the defaults), you should be able to find a queue names `pancancer_arch_3_orders`, with one message. If you examine the payload, it should look something like this:

    {
      "message_type": "order",
      "order_uuid": "a8430fe9-4866-4082-8e04-400e31124bde",
      "job": {
      "job_uuid" : "e389c296-ebe5-4206-b07d-3dd7847e4cf9",
      "workflow_name" : "HelloWorld",
      "workflow_version" : "1.0-SNAPSHOT",
      "workflow_path" : "/workflows/Workflow_Bundle_HelloWorld_1.0-SNAPSHOT_SeqWare_1.1.0",
      "job_hash" : "param1=bar,param2=foo",
      "arguments" : {
        "param1" : "bar",
        "param2" : "foo"
      }
    },
      "provision": {   "message_type": "provision",
    "provision_uuid": "",
       "cores": 8,
        "mem_gb": 128,
        "storage_gb": 1024,
        "job_uuid": "e389c296-ebe5-4206-b07d-3dd7847e4cf9",
        "ip_address": "",
        "bindle_profiles_to_run": ["ansible_playbook_path"
    ]
    }

    }

You can then run the coordinator to conver this Order message into a Job and a VM Provision Request:

    Coordinator --config config/masterConfig.ini

At this point, the RabbitMQ console should show 0 messages in `pancancer_arch_3_order` and 1 message in `pancancer_arch_3_jobs` and 1 message in `pancancer_arch_3_vms`. The messages in these queues are in fact the two parts of the message above: the first part of that message was the Job, the second part was the VM Provision Request.

Finally, you can run a worker manually to execute a single job. Log in to a worker and run this command

    java -cp ~/arch3/bin/pancancer-arch-3-*.jar info.pancancer.arch3.worker.Worker --config workerConfig.ini --uuid 12345678 &

If the worker runs, you can check the log file (`arch3.log`), you should see that there are 0 messages in the Job queue. You may also see some messages in `pancancer_arch_3_for_CleanupJobs`, which will contain the heartbeat from the worker (since HelloWorld finishes very quickly, you may want to speed up the heartbeat, to a rate of 1 message per second for the purposes of this test). There should be a message indicating completeness:

    {
      "type": "job-message-type",
      "state": "SUCCESS",
      "vmUuid": "12345678",
      "jobUuid": "e389c296-ebe5-4206-b07d-3dd7847e4cf9",
      "message": "job is finished",
      "stderr": "",
      "stdout": "Performing launch of workflow \u0027HelloWorld\u0027 version...[2015/07/07 18:03:46] | Setting workflow-run status to completed for: 10\n[--plugin, io.seqware.pipeline.plugins.WorkflowWatcher, --, --workflow-run-accession, 10]\nWorkflow run 10 is currently completed\n[--plugin, net.sourceforge.seqware.pipeline.plugins.WorkflowStatusChecker, --, --workflow-run-accession, 10]",
      "ipAddress": "10.0.26.25"
    }

Similar information can also be seen in the worker's `arch3.log` file.

#### Regular Operations

Note that you should probably run these commands in the home directory or somewhere else you want the resulting log files to appear.

You will then be able to kick-off the various services and submit a test job:

    Generator --config ~/arch3/config/masterConfig.ini --workflow-name HelloWorld --workflow-version 1.2.0 --workflow-path /workflows/Workflow_Bundle_HelloWorld_1.2.0_Seqware_1.1.0 --total-jobs 5

    Coordinator --config ~/arch3/config/masterConfig.ini --endless &

    Provisioner --config ~/arch3/config/masterConfig.ini --endless &

When those jobs complete, you can then submit real jobs using the following command assuming that your ini files are in ini\_batch\_5:

    Generator --workflow-name Sanger --workflow-version 1.0.7 --workflow-path /workflows/Workflow_Bundle_SangerPancancerCgpCnIndelSnvStr_1.0.7_SeqWare_1.1.0 --config ~/arch3/config/config.json --ini-dir ini_batch_5

Note that while coordinator.out and provisioner.out contain only high-level information such as errors and fatal events, the arch3.log which is automatically generated (and rotates) contains low level logging information.

You should also start off the Reporting Bot (this will be integrated in a future release of the pancancer launcher)

    cd ~/arch3/
    ReportBot --endless --config ~/arch3/config/masterConfig.ini &

See [arch3](https://github.com/CancerCollaboratory/sandbox/blob/develop/pancancer-arch-3/README.md) for more details.

To set up reporting, see the [README.md](https://github.com/CancerCollaboratory/sandbox/tree/develop/pancancer-reporting) for that component.

#### Dealing with Failure

When workflows fail, arch3 will leave that host in place for you to examine. Your task as a cloud shepherd is to take a look, determine the problem, and if the problem is epehemeral (i.e. like a temporary network outage) to requeue the job.

1. First, reporting tools will tell you to look at a node.

        green_snake status
        ....
        There are failed jobs on VMs that require attention:
        d957d16e-335d-46fc-850c-9aa1de896151
        first seen (hours) 21.60
        ip_address 10.106.128.62
        last seen (seconds) 30490.90
        status FAILED

1. For now, retrieve the ini file from the failed workers

        mkdir ini_batch_5_failed && cd ini_batch_5_failed
        scp -i ~/.ssh/green_snake.pem ubuntu@10.106.128.62:/tmp/*.ini .
        The authenticity of host '10.106.128.62 (10.106.128.62)' can't be established.ECDSA key fingerprint is e9:bf:fb:f3:d0:29:95:82:08:fe:8d:73:07:6a:2e:35.
        Are you sure you want to continue connecting (yes/no)? yes
        Warning: Permanently added '10.106.128.62' (ECDSA) to the list of known hosts.
        seqware_9050325771159466321.ini
        cd ..

1.  Resubmit the job

        java -cp ~/arch3/bin/pancancer-arch-3-*.jar info.pancancer.arch3.jobGenerator.JobGeneratorDEWorkflow --workflow-name BWA --workflow-version 2.6.1 --workflow-path /workflows/Workflow_Bundle_BWA_2.6.1_SeqWare_1.1.0-alpha.5 --config ~/arch3/config/masterConfig.ini --ini-dir ini_batch_5_failed/

1. Terminate the hosts with the failed jobs in either the AWS console, Azure portal, or OpenStack horizon using the above ip_address to search.  

#### Causing a Failure

##### Causing a Workflow Step Failure

If you find yourself in a situation where you want to cause a particular workflow step to fail, you can "kill -9" the specific tool in question. SeqWare should step in and retry that particular step up to a limit defined in your ~/.seqware/settings file. See [the procedure for the VCF upload tool](https://github.com/ICGC-TCGA-PanCancer/vcf-uploader#stuck-uploads) for a specific example.

##### Causing a Workflow Failure

If you need to engineer a workflow fail. A "kill -9" on the "docker run" on the worker is sufficient to indicate a failure to arch3. Afterwards, you can terminate the worker without any worries of getting the DB and rabbitmq out of sync.

#### Debugging and trouble-shooting

For debugging, you can login to the RabbitMQ web interface at port 15672 using a web browser. The URL usually looks like

    http://<your launcher's public IP address>:15672/

*Note: You must ensure that your launcher's security group allows traffic on port 15672.

You can also examine th database by loggng in to postgres using this command:


    psql -U queue_user queue_status


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

When running your workflows, you will probably want to use an INI file generated by the Central Decider Client. Please [click here](https://github.com/ICGC-TCGA-PanCancer/pancancer-documentation/blob/3.1.4/production/central_decider_client.md#the-central-decider-client) for more information on how to get the INI files and how they can be submitted to a worker node.

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

## Upgrading

### Upgrading pancancer\_launcher
The recommended process for upgrading to a new version of pancancer\_launcher is:

 1. Start a new VM.
 2. Install docker
 3. Pull the newer docker image.
 4. Begin scheduling new jobs.

At the same time, you should also stop scheduling new jobs on your old launcher host. There will be a period of time when you will have two launcher hosts and two fleets running beside each other.

If you wish to avoid having two fleets, you can stop scheduling in your old launcher, wait for all workers to finish their work, destroy the old launcher, and then create a new launcher (on your existing VM, if you want) with a newer version of the pancancer\_launcher image. It is *not* recommended to run two pancancer\_launcher containers on the same VM at the same time.

###  Upgrading workflows on workers
To upgrade the version of workflows on workers, update the `~/params.json` file and change the version number of the workflow. All new workers will use the version referenced in `params.json`.

## Known Issues

### Issues related to installing Docker
Sometimes the docker install process will hang. This usually happens when it tries to apply a kernel update. One workaround for this is to execute these commands and then install docker:

    sudo apt-get install linux-image-extra-$(uname -r)
    sudo modprobe aufs

It might be necessary to simply terminate a launcher host whose docker installation gets stuck at this point, and then start a new one and run these commands *before* attempting to install docker.

### Issues related to networking

#### Proxies
If your launcher host is behind proxies, make sure that they will allow this host to connect to dockerhub to download the docker images. Dockerhub may also store docker redirect a "docker pull" request to their main storage servers, so ensure that your proxies allow access to those servers as well.
