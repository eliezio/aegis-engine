# Cloud Infra Engine

The Cloud Infra Engine is created based on OPNFV Cross Community CI (XCI)
project in order to automate deployment of various cloud infra scenarios. [1]

# Prerequisites

Cloud Infra Engine lets users to deploy the scenario of their choosing on to
their workstations. Minimum requirements for the host where the Cloud Infra
Engine is executed are

* 8 CPUs
* 16 GB of RAM
* 200 GB of disk space
* nested virtualization support
* internet connection

Recommended requirements are

* 10 CPUs
* 20 GB RAM

The engine currently only supports Ubuntu16.04.

Apart from having sufficient performance and capacity on the host, few packages
need to be installed on the host before executing the engine

* git
* python
* libvirt

The user that is executing the engine should also have passwordless sudo enabled.

# Usage Instructions

Cloud Infra Engine is version controlled on Nordix Gerrit so its repository needs
to be cloned.

```bash
git clone https://gerrit.nordix.org/infra/engine.git
```

Cloud Infra Engine expects the ssh keys to be created in advance. If you don't have
ssh keypair already, you can do that by executing below command.

```bash
ssh-keygen -t rsa
```

Once the keypair is generated, the main script **deploy.sh** can be executed in order
to start deployment of the default scenario on virtual machines that are created by
the engine.

```bash
cd engine/engine
./deploy.sh -h # get help
./deploy.sh -c
```

Once the script execution starts, it will prepare the environment, create libvirt
resources, provision libvirt vms and install the selected scenario on them. The overall
process takes about 40 minutes to complete if ramdisk and deployment images are created
in advance.

Please note, in the default / embeded pdf / idf files, we have specified two disks
for each vms we are going to create. If you are going to provide pdf / idf files yourself
with mulitple disks, please note the current deployment script will not work when
the disks have the same size as we specify the bootable disk based on size.

# References

[1] https://opnfv-releng-xci.readthedocs.io/en/latest/
