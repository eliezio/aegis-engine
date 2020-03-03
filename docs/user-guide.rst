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


Testing the offline deployment
==============================

The engine offers a beta support for offline installation which requires the
presence of a tar file containing all the required dependencies. For now, the
only scenario supported is k8s-calico-nofeature with ceph as an installable
app.

Offline dependencies
--------------------

* Repositories
* Python packages
* Apt packages and apt proxy (apt-cacher-ng) debian package
* Docker images
* Docker official repository key
* Kubespray related binaries
* Helm binaries
* OS related images if not created through DIB
* Engine inventory (pdf.yml and idf.yml)

How to fetch the offline dependencies
-------------------------------------

Engine requires multiple dependencies, most of which are quite easy to obtain.
Hopefully this process can be automated soon enough.

In the current beta version, the offline mode assumes there is a tar file
containing all required dependencies in *$HOME/offline-dependencies.tar.gz*.
This tar file is produced when compressing a folder named *offline_files* in
this guide with the following structure.

::

   offline_files/
   ├── apt
   ├── apt-cacher-ng_3.1-1build1_amd64.deb
   ├── docker.key
   ├── helm
   ├── images
   ├── kubespray_cache
   ├── pip
   └── repos

   6 directories, 2 files

The easiest way to get most of the dependencies is to execute the engine in the
"Fetch dependencies" mode. For this, a capable machine (as described in the
above requirements) with Internet connectivity is needed. The process is
comprised of the following steps:

1. Create a local folder for dependencies.
::

   mkdir $HOME/offline_files

2. Execute the engine in "Fetch dependencies mode". This mode will be always
triggered when an offline deployment happens (-x option) and the tar file
containing the depencies is not present in the specified path.
::

   cd engine/engine
   ./deploy.sh -x

3. Read the details in `Apt packages`_ and save them in the local dependencies
folder.
::

   mkdir $HOME/offline_files/apt
   cp -r /var/cache/apt-cacher-ng/. $HOME/offline_files/apt
   wget http://archive.ubuntu.com/ubuntu/pool/universe/a/apt-cacher-ng/apt-cacher-ng_3.1-1build1_amd64.deb
   mv apt-cacher-ng_3.1-1build1_amd64.deb $HOME/offline_files

4. Kubespray will store its cache in the machine where the engine is executed
from. Please refer to `Kubespray cache`_ for detail instructions.

5. Read the details in `Docker official apt key`_ to download the key and place
it in the local dependencies folder.
::

   wget https://download.docker.com/linux/ubuntu/gpg
   mv gpg $HOME/offline_files/docker.key

6. Refer to the section `Helm binaries`_ for detail instructions.

7. Both python and pip have to be configured. Refer to `Python packages`_ for
more information.

8. Copy the necessary repositories with the commands provided in
`Repositories`_.

9. OS images can be created during runtime. However, the offline method
will use precompiled ones to speed up the deployment. Follow the instructions
in `OS images`_.

10. Kubespray does not include the post-deployment apps that are installed
with the engine, e.g. Ceph. For this reason, follow the instructions in
`Missing Docker images`_ to get all the dependencies.

10. Generate the tar.gz file
::

   cd $HOME/offline_files
   tar -zvcf $HOME/offline-dependencies.tar.gz *

11. Copy the dependencies tar file and the engine to your offline machine and
download idf and pdf files from Nordix.
::

   https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml;h=c02300c7060f1663bcc7e48ac0448f69bc034ea0;hb=refs/heads/master
   https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml;h=7e2a6f00375a4d31d7313ae7e0ad7fdb859d0ece;hb=refs/heads/master

12. Execute the engine and sit back.
::

   ./deploy.sh -cx -i file:///home/ubuntu/idf.yaml -p file:///home/ubuntu/pdf.yaml

Apt packages
************

Apt-cacher-ng has been used to set-up an apt proxy in the machine where the
deployment is initiated (a.k.a. kickstart machine). This piece of software
creates a local cache of the Debian mirrors (or other distributions too) which
are stored by default in */var/cache/apt-cacher-ng*.

During the first execution, i.e. "Fetch dependencies" mode, that local folder
will store all packages dowloaded by apt. Once the engine has successfully
finished, the contents of that folder should be placed in the local
dependencies folder *$HOME/offline_files/apt*.

Additionally, the Debian package for apt-cacher-ng should be downloaded by the
users and placed in the local dependencies folder
*$HOME/offline_files/apt-cacher-ng_3.1-1build1_amd64.deb*.

In some cases, we might not start with a fresh empty machine and some engine
depedencies could be already installed in the system. Then apt usually ignores
those entries and apt-cacher-ng becomes unable to capture and cache those
packages. The following command might help to force the download.
::

   dpkg -l | grep "^ii"| awk ' {print $2} ' | xargs sudo apt-get -y --force-yes install --reinstall --download-only


Right now, apt-cacher-ng is not behaving as expected with mirrors, so please
override your apt sources.list with the default Ubuntu.
::

   deb http://archive.ubuntu.com/ubuntu bionic main universe
   deb http://archive.ubuntu.com/ubuntu bionic-updates main universe
   deb http://archive.ubuntu.com/ubuntu bionic-backports main universe
   deb http://archive.ubuntu.com/ubuntu bionic-security main universe

Kubespray cache
***************

After the first execution, Kubespray will store its cache in the machine where
the engine is initiated under */tmp/kubespray_cache*. Its structure should look
something like this (versions could differ).
::

   /tmp/kubespray_cache/
   ├── calicoctl
   ├── cni-plugins-linux-amd64-v0.8.1.tgz
   ├── images
   │   ├── docker.io_calico_cni_v3.7.3.tar
   │   ├── docker.io_calico_kube-controllers_v3.7.3.tar
   │   ├── docker.io_calico_node_v3.7.3.tar
   │   ├── docker.io_coredns_coredns_1.6.0.tar
   │   ├── docker.io_lachlanevenson_k8s-helm_v2.16.1.tar
   │   ├── docker.io_library_nginx_1.17.tar
   │   ├── gcr.io_google-containers_addon-resizer_1.8.3.tar
   │   ├── gcr.io_google-containers_cluster-proportional-autoscaler-amd64_1.6.0.tar
   │   ├── gcr.io_google-containers_k8s-dns-node-cache_1.15.5.tar
   │   ├── gcr.io_google-containers_kube-apiserver_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-controller-manager_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-proxy_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-scheduler_v1.17.0.tar
   │   ├── gcr.io_google-containers_pause_3.1.tar
   │   ├── gcr.io_google_containers_kubernetes-dashboard-amd64_v1.10.1.tar
   │   ├── gcr.io_google_containers_metrics-server-amd64_v0.3.3.tar
   │   ├── gcr.io_google_containers_pause-amd64_3.1.tar
   │   ├── gcr.io_kubernetes-helm_tiller_v2.16.1.tar
   │   └── quay.io_coreos_etcd_v3.3.10.tar
   ├── kubeadm-v1.17.0-amd64
   ├── kubectl-v1.17.0-amd64
   └── kubelet-v1.17.0-amd64

   1 directory, 24 files

An extra configuration is required before copying to the local dependencies
folder. The naming convention used by Kubespray to save the images is
unfortunately not consistent with the one used in the current version of
docker. The issues is that some images files will have a "docker.io" prefix in
the name of the tar file, while once the image is loaded into the node's memory
this prefix dissapears since it is the default Docker registry. As a result,
Kubespray playbook is not able to find the local copy of the image and fails.
For the renaming purpose, your can use the following commands.
::

   cd /tmp/kubespray_cache/images
   for file in docker.io_*; do mv -i "$file" "${file#docker.io_}"; done
   mv library_nginx_1.17.tar nginx_1.17.tar

These changes can be noticed in the folder structure, compared to the above.
::

   /tmp/kubespray_cache/
   ├── calicoctl
   ├── cni-plugins-linux-amd64-v0.8.1.tgz
   ├── images
   │   ├── calico_cni_v3.7.3.tar
   │   ├── calico_kube-controllers_v3.7.3.tar
   │   ├── calico_node_v3.7.3.tar
   │   ├── coredns_coredns_1.6.0.tar
   │   ├── gcr.io_google-containers_addon-resizer_1.8.3.tar
   │   ├── gcr.io_google-containers_cluster-proportional-autoscaler-amd64_1.6.0.tar
   │   ├── gcr.io_google-containers_k8s-dns-node-cache_1.15.5.tar
   │   ├── gcr.io_google-containers_kube-apiserver_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-controller-manager_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-proxy_v1.17.0.tar
   │   ├── gcr.io_google-containers_kube-scheduler_v1.17.0.tar
   │   ├── gcr.io_google-containers_pause_3.1.tar
   │   ├── gcr.io_google_containers_kubernetes-dashboard-amd64_v1.10.1.tar
   │   ├── gcr.io_google_containers_metrics-server-amd64_v0.3.3.tar
   │   ├── gcr.io_google_containers_pause-amd64_3.1.tar
   │   ├── gcr.io_kubernetes-helm_tiller_v2.16.1.tar
   │   ├── lachlanevenson_k8s-helm_v2.16.1.tar
   │   ├── nginx_1.17.tar
   │   └── quay.io_coreos_etcd_v3.3.10.tar
   ├── kubeadm-v1.17.0-amd64
   ├── kubectl-v1.17.0-amd64
   └── kubelet-v1.17.0-amd64

   1 directory, 24 files

Finally, we can copy these files into the local dependencies folder.
::

   cp -r /tmp/kubespray_cache $HOME/offline_files

Docker official apt key
***********************

Kubespray uses apt-key to install the official docker repository key.
Unfortunately, this command does not work under a proxy. For this reason, for
our use case is necessary to download the file previous to the execution, pass
it to the nodes and install it. The engine will take care of the latter steps.

Helm binaries
*************

They are not included in Kubespray cache and should be downloaded prior to the
offline execution. Use the following commands and modify accordingly to match
the desired helm version.
::

   mkdir $HOME/offline_files/helm
   wget https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz
   mv helm-v2.16.1-linux-amd64.tar.gz $HOME/offline_files/helm

Python packages
***************

Get the dependencies versions and packages into the pip folder.
::

   mkdir $HOME/offline_files/pip
   cd $HOME/offline_files/pip
   pip download -r <path-to-engine>requirements.txt --no-cache


Besides, pip requires a special configuration to default to local files
instead of trying to fecth packages from remote. Place the following snippet
under *$HOME/offline_files/pip/pip.conf*
::

   cat << EOF > $HOME/offline_files/pip/pip.conf
   [global]
   timeout=10
   find-links=/opt/engine/.cache/offline/pip
   no-index=yes
   EOF

Repositories
************

The engine uses multiple repositories during its execution. Here is a detailed
list of repositories that should be downloaded and placed in
*$HOME/offline_files/repos*.

These repositories can be found in */opt/engine/.cache/repos*

* bifrost
* kubespray
* swconfig

These repositories can be found in */opt/stack*.

* diskimage-builder
* ironic
* ironic-inspector
* ironic-python-agent
* ironic-python-agent-builder
* ironic-staging-drivers
* keystone
* openstacksdk
* python-ironic-inspector-client
* python-ironicclient
* requirements
* shade
* sushy

These commands will help you in this process.
::

   mkdir $HOME/offline_files/repos
   cp -r /opt/engine/.cache/repos/. $HOME/offline_files/repos
   for git_directory in $HOME/offline_files/repos/* ; do (cd "$git_directory" && git checkout . && git clean -f); done
   cp -r /opt/stack/. $HOME/offline_files/repos

OS images
*********

After the first execution, OS images can be found in */httpboot*

These three files should be copied to *$HOME/offline_files/images*:
* deployment_image.qcow2
* ipa.initramfs
* ipa.kernel
::

   mkdir $HOME/offline_files/images
   cp /httpboot/ipa* $HOME/offline_files/images/
   cp /httpboot/deployment_image.qcow2 $HOME/offline_files/images/

Missing Docker images
*********************

Unfortunately, not all docker images necessary to execute the engine will be
present in the Kubespray cache folder. For instance, those required for any
post deployment application like Ceph.

The following images should be manually downloaded (for now) and placed under
the directory *offline_files/kubespray_cache/images*. Once the "Fetch
dependencies" is finished, access the worker node to use the docker daemon.
::

   ssh root@node1_ip_address
   mkdir /tmp/extra-docker-images
   cd /tmp/extra-docker-images
   docker pull ceph/ceph:v14.2.4-20190917
   docker save ceph/ceph:v14.2.4-20190917 -o ceph_ceph_v14.2.4-20190917.tar
   docker pull rook/ceph:v1.1.2
   docker save rook/ceph:v1.1.2 -o rook_ceph_v1.1.2.tar
   docker pull quay.io/cephcsi/cephcsi:v1.2.1
   docker save quay.io/cephcsi/cephcsi:v1.2.1 -o quay.io_cephcsi_cephcsi_v1.2.1.tar
   docker pull quay.io/k8scsi/csi-node-driver-registrar:v1.1.0
   docker save quay.io/k8scsi/csi-node-driver-registrar:v1.1.0 -o quay.io_k8scsi_csi-node-driver-registrar_v1.1.0.tar
   docker pull quay.io/k8scsi/csi-attacher:v1.2.0
   docker save quay.io/k8scsi/csi-attacher:v1.2.0 -o quay.io_k8scsi_csi-attacher_v1.2.0.tar
   docker pull quay.io/k8scsi/csi-provisioner:v1.3.0
   docker save quay.io/k8scsi/csi-provisioner:v1.3.0 -o quay.io_k8scsi_csi-provisioner_v1.3.0.tar
   docker pull quay.io/k8scsi/csi-snapshotter:v1.2.0
   docker save quay.io/k8scsi/csi-snapshotter:v1.2.0 -o quay.io_k8scsi_csi-snapshotter_v1.2.0.tar
   exit
   cd $HOME/offline_files/kubespray_cache/images
   scp -r root@node1_ip_address:/tmp/extra-docker-images/* .

The final list of docker images in that folder should look like this:
::

   /home/ubuntu/offline_files/kubespray_cache/images/
   ├── calico_cni_v3.7.3.tar
   ├── calico_kube-controllers_v3.7.3.tar
   ├── calico_node_v3.7.3.tar
   ├── ceph_ceph_v14.2.4-20190917.tar
   ├── coredns_coredns_1.6.0.tar
   ├── gcr.io_google-containers_addon-resizer_1.8.3.tar
   ├── gcr.io_google-containers_cluster-proportional-autoscaler-amd64_1.6.0.tar
   ├── gcr.io_google-containers_k8s-dns-node-cache_1.15.5.tar
   ├── gcr.io_google-containers_kube-apiserver_v1.17.0.tar
   ├── gcr.io_google-containers_kube-controller-manager_v1.17.0.tar
   ├── gcr.io_google-containers_kube-proxy_v1.17.0.tar
   ├── gcr.io_google-containers_kube-scheduler_v1.17.0.tar
   ├── gcr.io_google-containers_pause_3.1.tar
   ├── gcr.io_google_containers_kubernetes-dashboard-amd64_v1.10.1.tar
   ├── gcr.io_google_containers_metrics-server-amd64_v0.3.3.tar
   ├── gcr.io_google_containers_pause-amd64_3.1.tar
   ├── gcr.io_kubernetes-helm_tiller_v2.16.1.tar
   ├── lachlanevenson_k8s-helm_v2.16.1.tar
   ├── nginx_1.17.tar
   ├── quay.io_cephcsi_cephcsi_v1.2.1.tar
   ├── quay.io_coreos_etcd_v3.3.10.tar
   ├── quay.io_k8scsi_csi-attacher_v1.2.0.tar
   ├── quay.io_k8scsi_csi-node-driver-registrar_v1.1.0.tar
   ├── quay.io_k8scsi_csi-provisioner_v1.3.0.tar
   ├── quay.io_k8scsi_csi-snapshotter_v1.2.0.tar
   └── rook_ceph_v1.1.2.tar

   0 directories, 26 files

Disable Prometheus
------------------

In order to speed up the development, Prometheus installation is not covered
yet in offline mode. Please disable it in sdf.yml. This snippet shows where
is the file and what should be modified.

::

   diff --git a/engine/inventory/group_vars/all/sdf.yaml b/engine/inventory/group_vars/all/sdf.yaml
   --- a/engine/inventory/group_vars/all/sdf.yaml
   +++ b/engine/inventory/group_vars/all/sdf.yaml
   @@ -50,7 +50,6 @@ scenario:
            - centos7
            curated_apps:
            - ceph
   -          - prometheus
      k8-flannel-nofeature:
      scm: git
      src: https://gerrit.nordix.org/infra/swconfig.git

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

  | ``ssh-keygen -t rsa``

* Your user must be member of **sudo** group and have passwordless
  sudo enabled. Click `here <https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions>`_
  for how to do this.

Please follow the steps below to get the package created for offline deployments.

.. caution:: **Use regular user**

  All the commands in this guide must be executed as **regular** user
  and not as **root** user! The framework elevates privileges itself
  as necessary.

1. Clone the framework repository from Nordix Gerrit

   | ``git clone https://gerrit.nordix.org/infra/engine.git``

2. Navigate to engine directory in your clone

   | ``cd engine/engine``

3. Issue the command to initiate the packaging process

   | ``./package.sh``

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

  | ``ssh-keygen -t rsa``

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

   | ``/home/ubuntu/k8s-installer-ubuntu1804.bsx``

2. Navigate to engine directory

   | ``cd /opt/engine/offline/git/engine/engine``

3. Issue the command to initiate the deployment process

   | ``./deploy.sh -c -x -p file:///opt/engine/offline/git/hwconfig/pods/nordix-vpod1-pdf.yml -i file:///opt/engine/offline/git/hwconfig/pods/nordix-vpod1-idf.yml``

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

   | ``kubectl get nodes``

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

  | ``ssh-keygen -t rsa``

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

   | ``/home/ubuntu/k8s-installer-ubuntu1804.bsx``

2. Navigate to engine directory

   | ``cd /opt/engine/offline/git/engine/engine``

3. Issue the command to initiate the deployment process

   | ``./deploy.sh -c -x -p <path to PDF file> -i <path fo IDF file>``


After the succesful completion of the deployment, you should be able to issue
**kubectl** commands on the machine you initiated the deployment on to operate
against the cluster you just deployed.

   | ``kubectl get nodes``

Testing the Deployment
**********************

Documentation for how to test the deployments will be available soon.
