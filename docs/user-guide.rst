.. _framework-user-guide:

===========================================
Cloud Infra Automation Framework User Guide
===========================================

Introduction
============

Cloud Infra Automation Framework provides one-command deployments
of various open source cloud technologies and different configurations
of those.

This guide is structured in a way to give the users the most basic
way to start using the framework. Later sections are structured after
the technologies as they have differences such as the target environment
support and so on.

Running Your First Deployment
=============================

In order to give a quick try to framework and see its capabilities,
you need to run **3** commands in total. Once the execution of the command
is completed, you will have fully functional platform which you can play
with or get rid of it and deploy another and perhaps different one
that serves your needs better.

Requirements
------------

Before proceeding with the steps, it is important to list the requirements
for this simple stack. You need to have a decent Linux computer with
the distro and specs below.

* Linux Distribution: Ubuntu 1804
* Minimum no of cores: 10
* Minimum RAM: 14G
* Minimum Disk Space: 150G

If you do not have a computer which meets the minimum requirements, you can
always reach out to Nordix Infra Team on `Nordix Discuss Maillist <https://lists.nordix.org/mailman/listinfo/discuss>`_
and asks to borrow resources for trying things out.

Deploy Now!
-----------

As promised above, here are the commands you need to run to get your
first deployment started. We will start with cloning the Git repository
where the framework is developed and version controlled followed by the
actual command to initiate the deployment.

1. Clone the repository from Nordix Gerrit

.. code-block:: bash

   git clone https://gerrit.nordix.org/infra/engine.git

2. Navigate to engine directory in your clone

.. code-block:: bash

   cd engine/engine

3. Issue the command to initiate the deployment

.. code-block:: bash

   ./deploy.sh

and that's it. It will take approximately 40 to 50 minutes for deployment
to complete.

What Just Happened and What You Have There?
-------------------------------------------

When you issue *deploy.sh* command, the framework starts with preparing
your machine by installing few requirements which you can see by looking
into *engine/bindep.txt* followed by creating of Python virtualenv to
install Python dependencies listed in *engine/requirements.txt*.

Once the basic preparation is done, the next step is cloning the repositories
that are needed for framework to continue with the rest.

After completion of this step, framework creates 2 libvirt VMs and installs the
provisioning tool `OpenStack Bifrost <https://docs.openstack.org/bifrost/latest/>`_.
After the installation of the provisioning tool, the VMs are booted up
and the provisioning process starts. The VMs will be PXE booted and they
are supplied the operating system images which is Ubuntu 1804. They
are remotely controlled by Bifrost to power cycle which the framework
uses `OpenStack VirtualBMC <https://docs.openstack.org/virtualbmc/latest/user/index.html>`_.

After the completion of the provisioning, the VMs have remote connectivity
but their configuration is incomplete. At this step, the framework proceeds
with various configuration steps on the VMs such as installing operating system
packages network configuration and so on.

Basic configuration of the VMs is followed by yet another clone operation
which we pull down the installer for the platform we have chosen to install.
The default configuration that gets deployed by the framework is Kubernetes
with Calico Network Plugin. The framework uses another open source tool
from CNCF named `Kubespray <https://github.com/kubernetes-sigs/kubespray>`_.
Kubespray is a `CNCF certified Kubernetes Distribution <https://www.cncf.io/certification/software-conformance/>`_
so what you get in the end is pretty solid. In addition to Kubernetes itself
with Calico Network Plugin, the stack will have `Helm <https://helm.sh/>`_
and `Prometheus <https://prometheus.io/>`_ so you can use this deployment
for real development purposes.

Once the installation of Kubernetes together with the components end, you
will be presented with a summary and the script will exit successfully - at
least this is what we hope at this point. You should have **kubectl** and
**helm** client installed on your machine to operate against Kubernetes cluster.

We already noted what you get in the end but we list them here as well to
summarize the deployment you have.

* Platform: Kubernetes
* Network Plugin: Calico
* Storage: CEPH installed using Rook
* Application Development: Helm
* Metrics/Monitoring: Prometheus

Congratulations, you made it! \\o/

Scenarios Supported by Cloud Infra Automation Framework
=======================================================

As noted in earlier sections, the framework supports various scenarios. In
this section, we will provide steps to deploy those scenarios and operate
against them. This part of the guide is structured after the platforms
as the scenarios are platform specific.

OpenStack Scenarios
-------------------

Engine currently supports single OpenStack scenario with OVS and CEPH.
Deployment of this scenario is same as the default scenario you deployed
by following the steps documented in *Running Your First Deployment*
with few additional parameters to set the right scenario.


The machine requirements are same as the one you deployed earlier but
putting them here as well for the sake of completion.

* Linux Distribution: Ubuntu 1804
* Minimum no of cores: 10
* Minimum RAM: 14G
* Minimum Disk Space: 150G

What happens during the deployment process is nearly the same as the default
scenario as well - the framework creates libvirt VMs, provisions them using
Bifrost, and configures them. The main difference here is the configuration
as the network setup for OpenStack deployments is different from Kubernetes
deployments.


Provisioning is followed by installation of OpenStack which is perhaps the
biggest difference comparing to the deployment of the Kubernetes based default
scenario. For OpenStack installation, framework utilizes OpenStack installer
`Kolla-Ansible <https://docs.openstack.org/kolla-ansible/latest/>`_.


Now the commands to issue.

1. Clone the repository from Nordix Gerrit - *you can skip this step if you have the clone already*

.. code-block:: bash

   git clone https://gerrit.nordix.org/infra/engine.git

2. Navigate to engine directory in your clone

.. code-block:: bash

   cd engine/engine

3. Issue the command to initiate the deployment

.. code-block:: bash

   ./deploy.sh -d kolla -s os-nosdn-nofeature -c

Once the installation of OpenStack together with the components end, you
will be presented with a summary and the script will exit successfully.
Your machine will have the OpenStack clients installed and openrc file
so you can operate against your deployment. Please note that you may
need to activate Python virtual environment to access them which you
can do using the command below.

.. code-block:: bash

   source /opt/engine/.venv/bin/activate

We already noted what you get in the end but we list them here as well to
summarize the deployment you have.


* Platform: OpenStack
* Networking: Neutron with OVS
* Storage: CEPH


Installed OpenStack components are

* Keystone
* Nova
* Neutron

  - OVS
  - VXLAN

* Heat
* Glance
* Cinder

  - CEPH as volume backend
  - NFS as backup backend

* Horizon

Installed infra services are

* RabbitMQ
* MariaDB
* Memcached
* Chrony
* Fluentd

Kubernetes Scenarios
--------------------

TBD

ONAP Scenarios
--------------

TBD

Testing Your Deployments
========================

TBD

Offline Packaging, Deployment and Testing
=========================================

Nordix Cloud Infra Automation Framework supports packaging of open source technologies
for offline installation in closed environments where internet access is either not
available or not desired due to security reasons.

The framework enables this by packaging open source dependencies necessary to provision
cloud, virtual, and baremetal resources and install stack on the provisioned resources. In
addition to providing dependencies for provisioning and installation, test frameworks and
test cases are also packaged so the deployment can be verified. The resulting package
can then be put on to a USB stick or burnt to a DVD for installing in a closed environment
where there is no internet connection.

Following sections describe the details of the implementation followed by user guide.

Please note that the current implementation can be considered as *beta* as it lacks
support for key items and it is not time optimized. Further work will be done to introduce
support for additional technologies and improve the user experience.

Supported Technologies
----------------------

Nordix Cloud Infra Automation Framework utilizes open source tools to provision
nodes, install various technologies on provisioned nodes, and test deployments.
In order to enable packaging, offline deployments, and testing  of the relevant
technologies, the tools used to install those technologies require to be packaged
and configured to work in closed environments.

Following sections lists what technologies are currently supported and which tools
are used in different phases.

Provisioning
************

Provisioning is the operation of making the nodes operational so the stack can be installed
on them. This includes and not limited to powering the nodes on and off remotely using remote
management protocols such as `IPMI <https://en.wikipedia.org/wiki/Intelligent_Platform_Management_Interface>`_,
providing Linux kernel to the nodes for initial boot, and supplying images so operating system
can be installed on disk. This is followed by initial network configuration so target nodes
are accessible via SSH and ready for further configuration and installation.

The framework uses `Bifrost <https://docs.openstack.org/bifrost/latest/>`_ for provisioning
virtual and baremetal nodes in a closed/offline environment. `Ubuntu 18.04 Bionic <http://releases.ubuntu.com/18.04/>`_
is the supported operating system both on jumphost and target nodes and support for other
other operating systems will be introduced on a need basis.

Installation
************

Installation phase includes configuring the provisioned nodes for the stack installation,
assigning roles to nodes based on the user needs, and installing stack on them. In some
cases, the installation of basic applications is also part of the stack installation.

The framework uses `Kubespray <https://kubespray.io/#/>`_ for installing `Kubernetes <https://kubernetes.io/>`_
on provisioned nodes in an offline environment. Ubuntu is the supported operating system
on target and support for other operating systems will be introduced on a need basis.

Kubernetes can be installed using the following network configurations.

* `Calico <https://www.projectcalico.org/>`_
* `Canal <https://docs.projectcalico.org/getting-started/kubernetes/installation/flannel>`_
* `Flannel <https://github.com/coreos/flannel>`_
* `Multus <https://github.com/intel/multus-cni>`_
* `Weave <https://www.weave.works/docs/net/latest/kubernetes/kube-addon/>`_

In addition to having capability to install Kubernetes with various network plugins,
installation of below applications in a closed environment is supported as well.

* `Rook CEPH <https://rook.io/>`_
* `Prometheus <https://prometheus.io/>`_

Testing
*******

The work to package and test the target deployments is still in progress.

User Guide
----------

In order to deploy Kubernetes using the framework in an offline environment, you need
the package that is generated by the framework itself. Users can either package the
dependencies themselves or fetch a promoted package that is produced and verified
by Nordix CI/CD.

Packaging
*********

In order to run the packaging, you need to have a machine with internet connectivity.
The minimum requirements for the machine are

* CPU: 2 cores
* RAM: 4GB
* Storage: 300GB
* OS: Ubuntu 18.04
* Software: git
* Passswordless sudo
* Internet connection

The packaging process is verified on Ubuntu 18.04 and Ubuntu 18.04.2 and it is expected
to work on latest Ubuntu 18.04 as well so you can attempt running packaging on a machine
with any Ubuntu 18.04 version you may already have.

In addition to the need of having capable computer with supported operating system, the
configuration of it needs to be adjusted as documented below.

* You must have SSH keypair generated before running any commands.
  If you have one already, you are good to go. If not, you can
  generate keypair using the command below.

.. code-block:: bash

  ssh-keygen -t rsa

* Your user must be member of **sudo** group and have passwordless
  sudo enabled. Click `here <https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions>`_
  for how to do this.

Please follow the steps below to get the package created for offline deployments.

.. caution:: **Use regular user**

  All the commands in this guide must be executed as **regular** user
  and not as **root** user! The framework elevates privileges itself
  as necessary.

1. Clone the framework repository from Nordix Gerrit

.. code-block:: bash

   git clone https://gerrit.nordix.org/infra/engine.git

2. Navigate to engine directory in your clone

.. code-block:: bash

   cd engine/engine

3. Issue the command to initiate the packaging process

.. code-block:: bash

   ./package.sh

After you issue **package.sh**  command, the packaging process will start, fetching the
dependencies from the internet. The packaging process could take up to 40 minutes depending
depending on the specs of the machine you are using and your connection speed & bandwidth.
During the packaging process, the framework fetches the dependencies listed below.

* Linux kernel and Operating System Images to boot and provision nodes.
* Operating system packages (Debian only)
* Python packages
* Git repositories
* Binaries/executables
* Container images
* Installation script

Upon completion of the packaging process, the self extracting archive file **/tmp/k8s-installer-ubuntu1804.bsx**
is created. This file is approximately 4GB.

You can now use this file to an offline environment to provision nodes and install
Kubernetes on them!

Advanced usage instructions will be made available soon.

Offline Deployment
******************

Offline installation is as simple as taking the generated self extracting archive file
**/tmp/k8s-installer-ubuntu1804.bsx**, copying it to jumphost, and executing it. Once the file
file is executed, the dependencies will be extracted **/opt/engine/offline** folder
which is where the framework will consume them during the deployment process. It is
important that you do not modify the contents of this folder manually.

Once the decompression ends, you will be instructed with regards to the next step
you need to take, which is initiating the actual deployment.

One important point to highlight here is that if you are provisioning and deploying
on baremetal nodes, you must ensure you have PDF and IDF files for the POD available
on jumphost and pass their location to engine **deploy.sh** script using **-p** and
**-i** arguments.

Offline deployment functionality can best be demonstrated using virtual machines as
the PDF and IDF files are delivered in the archive file. In order to try this out,
please ensure you have a machine with minimum requirements below.

* CPU: 12 cores
* RAM: 16GB
* Storage: 300GB
* OS: Ubuntu 18.04
* Software: git
* Passswordless sudo

In addition to the need of having capable computer, the configuration
of it needs to be adjusted as well.

* You must have SSH keypair generated before running any commands.
  If you have one already, you are good to go. If not, you can
  generate keypair using the command below.

.. code-block:: bash

  ssh-keygen -t rsa

* Your user must be member of **sudo** group and have passwordless
  sudo enabled. Click `here <https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions>`_
  for how to do this.
* Your machine should have **nested virtualization** enabled. Otherwise,
  the VMs that are going to be created by the framework will have
  bad performance due to not using qemu with kvm extensions. Click
  `this link <https://www.juniper.net/documentation/en_US/vsrx/topics/task/installation/security-vsrx-kvm-nested-virt-enable.html>`_
  to see how you can configure and verify nested virtualization.
  Please note that you may need to enable CPU nested virtualization
  capabilities on your computer's BIOS if you encounter any issues.
  Consult your computer's manual in this case.
* Framework will create libvirt networks 10.1.0.0/24, 10.2.0.0/24,
  10.3.0.0/24, and 10.4.0.0/24 for this deployment. You must ensure
  that these networks are not in use on your machine. Otherwise,
  the deployment will fail.

The steps below assume that you copied the self extracting archive file to
jumphost and it is located as **/home/ubuntu/k8s-installer-ubuntu1804.bsx**. If
the file is located some place else, please adjust the file path.

.. caution:: **Use regular user**

  All the commands in this guide must be executed as **regular** user
  and not as **root** user! The framework elevates privileges itself
  as necessary.

1. Execute the self extracting archive file

.. code-block:: bash

   /home/ubuntu/k8s-installer-ubuntu1804.bsx

2. Navigate to engine directory

.. code-block:: bash

   cd /opt/engine/offline/git/engine/engine

3. Issue the command to initiate the deployment process

.. code-block:: bash

   ./deploy.sh -x \
       -p file:///opt/engine/offline/git/hwconfig/pods/nordix-vpod1-pdf.yml \
       -i file:///opt/engine/offline/git/hwconfig/pods/nordix-vpod1-idf.yml

Once the command is issued, the deployment process will start with preparation
followed by bifrost installation, provisioning, and finally Kubernetes installation.
The installation could take up to 2 hours.

During the offline deployment process, several local services are provisioned
on jumphost to serve artifacts for consumption by jumphost and target hosts.
The local services and what they are served by them are listed below

* Nginx
    - Linux kernel and operating system images used for provisioning (only Ubuntu 18.04 currently)
    - OS Package mirror to serve packages (only Debian currently)
    - Mirror for Kubernetes binaries such as kubeadm, kubectl, kubelet
* Pip mirror: Python packages
* Git mirror: git repositories
* Local Docker Registry: Kubernetes and other relevant container images
* NTP Server: to provide time synchronization for the nodes within the POD

After the succesful completion of the deployment, you should be able to issue
**kubectl** commands on the machine you initiated the deployment on to operate
against the cluster you just deployed.

.. code-block:: bash

   kubectl get nodes

Baremetal deployments are same as the virtual deployments. As noted before, you must
have PDF and IDF files available on the machine.

In addition to having PDF and IDF files, jumphost should have the minimum  requirements
below.

* CPU: 4 cores
* RAM: 8GB
* Storage: 200GB
* OS: Ubuntu 18.04
* Software: git
* Passswordless sudo

Similar to virtual deployments, you must have SSH keys and your user must
be member of sudo group.

* You must have SSH keypair generated before running any commands.
  If you have one already, you are good to go. If not, you can
  generate keypair using the command below.

.. code-block:: bash

  ssh-keygen -t rsa

* Your user must be member of **sudo** group and have passwordless
  sudo enabled. Click `here <https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions>`_
  for how to do this.

.. caution:: **Use regular user**

  All the commands in this guide must be executed as **regular** user
  and not as **root** user! The framework elevates privileges itself
  as necessary.

The steps below assume that you copied the self extracting archive file to
jumphost and it is located as **/home/ubuntu/k8s-installer-ubuntu1804.bsx**. If
the file is located some place else, please adjust the file path.

1. Execute the self extracting archive file

.. code-block:: bash

   /home/ubuntu/k8s-installer-ubuntu1804.bsx

2. Navigate to engine directory

.. code-block:: bash

   cd /opt/engine/offline/git/engine/engine

3. Issue the command to initiate the deployment process

.. code-block:: bash

   ./deploy.sh -c -x -p <path to PDF file> -i <path fo IDF file>


After the succesful completion of the deployment, you should be able to issue
**kubectl** commands on the machine you initiated the deployment on to operate
against the cluster you just deployed.

.. code-block:: bash

   kubectl get nodes

Testing the Deployment
**********************

Documentation for how to test the deployments will be available soon.
