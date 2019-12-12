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
