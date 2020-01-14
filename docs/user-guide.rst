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

   | ``git clone https://gerrit.nordix.org/infra/engine.git``

2. Navigate to engine directory in your clone

   | ``cd engine/engine``

3. Issue the command to initiate the deployment

   | ``./deploy.sh``

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

Congratulations, you made it! \o/

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

   | ``git clone https://gerrit.nordix.org/infra/engine.git``

2. Navigate to engine directory in your clone

   | ``cd engine/engine``

3. Issue the command to initiate the deployment

   | ``./deploy.sh -d kolla -s os-nosdn-nofeature -c``

Once the installation of OpenStack together with the components end, you
will be presented with a summary and the script will exit successfully.
Your machine will have the OpenStack clients installed and openrc file
so you can operate against your deployment. Please note that you may
need to activate Python virtual environment to access them which you
can do using the command below.

   | ``source /opt/engine/.venv/bin/activate``

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
