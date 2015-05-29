# Based on Ubuntu 14
FROM ubuntu:14.04
MAINTAINER Solomon Shorser <solomon.shorser@oicr.on.ca>

# some packages needed by the other bags needed packages in "precise" but not in "trusty". Specifically, libdb4.8 was needed.
RUN apt-get install -y software-properties-common && \
    add-apt-repository "deb http://ca.archive.ubuntu.com/ubuntu precise main" && \
    add-apt-repository --yes ppa:rquillo/ansible && \
    add-apt-repository --yes ppa:ansible/ansible && \
    apt-get update
RUN apt-get install -y python-apt mcrypt git ansible vim curl build-essential libxslt1-dev libxml2-dev zlib1g-dev unzip wget make libipc-system-simple-perl libgetopt-euclid-perl libjson-perl libwww-perl libdata-dumper-simple-perl libtemplate-perl

# Create ubuntu user and group, make the account passwordless
RUN groupadd ubuntu && \
    useradd ubuntu -m -g ubuntu && \
    usermod -a -G sudo,ubuntu ubuntu && \
    passwd -d ubuntu

# setup packer, will be used for provisioning creating snapshots/AMIs
# RUN wget https://dl.bintray.com/mitchellh/packer/packer_0.7.5_linux_amd64.zip
# RUN mkdir /usr/local/bin/packer && mkdir packer-files && unzip packer_0.7.5_linux_amd64.zip -d /usr/local/bin/packer

USER ubuntu
ENV HOME /home/ubuntu
ENV USER ubuntu
WORKDIR /home/ubuntu

# setup .ssh and gnos.pem - user should move a valid keyfile in if they have one.
RUN mkdir ~/.ssh && touch ~/.ssh/gnostest.pem && \
    touch ~/.ssh/gnos.pem

# So we can get Ansible output as it happens (rather than waiting for the execution to complete).
ENV PYTHONUNBUFFERED 1
# Get code and run playbooks to build the container
RUN git clone https://github.com/ICGC-TCGA-PanCancer/architecture-setup.git && \
    cd architecture-setup && \
    git checkout 3.0.0 && \
    git submodule init && git submodule update && \
    git submodule foreach 'git describe --all' 
WORKDIR /home/ubuntu/architecture-setup
RUN ansible-playbook -i inventory site.yml
#WORKDIR /home/ubuntu/architecture-setup/youxia/youxia-setup
#RUN ansible-playbook -i inventory site.yml
#WORKDIR /home/ubuntu/architecture-setup/youxia/ansible_sensu
#RUN ansible-playbook -i inventory site.yml
WORKDIR /home/ubuntu/architecture-setup/

# The entry point of the container is start_services_in_container.sh, which will start up any necessary services, and also copy SSH pem keys and config files from the host. 
CMD ["/bin/bash","/home/ubuntu/start_services_in_container.sh"]

