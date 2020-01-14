.. _framework-overview:

=========================================
Cloud Infra Automation Framework Overview
=========================================

Introduction
============

Developers taking part in Nordix Community contribute to various open source
communities such as OpenStack, Kubernetes, and ONAP. Automation is crucial
for developers to easily bring up and tear down latest and greatest versions
of the open source technologies. Cloud Infra Automation Framework is developed
to address the needs of the developers and the Nordix Community at large.

Apart from enabling developers to access the technologies they need, Nordix
Community sees Continuous Integration (CI) and Continuous Delivery (CD) as
prerequisites for sustainable development. Cloud Infra Automation Framework
helps establishing CI/CD pipelines from the upstream communities in to Nordix.

Approach to Supporting Different Technologies and Compositions
==============================================================

There are very many different cloud and network automation technologies
Nordix Community members contribute to and this framework aims to provide
support for these technologies.

Cloud Infra Automation Framework uses a concept named *scenario*. A scenario
is a composition of different technologies, the features, and the
configurations that constitue the stack. An example to this could be Kubernetes
using Kata Containers as runtime and Flannel as network plugin. Another example
could be OpenStack using OVS DPDK and OpenDaylight as SDN Controller.

Current scenarios supported by the framework can be seen in the User Guide.

Technical Details of the Framework
==================================

Cloud Infra Automation Framework is written in Ansible. Bash scripts are
used as necessary in order to setup the environment for Ansible. More
details are available in the User Guide. If you intend to contribute to
the development of the framework to add new features or issue bugfixes,
you can take a look at Developer Guide which contains extensive information
about how things are structured.

Capabilities of the Framework
=============================

Cloud Infra Automation Framework has various capabilities which help developers
and users to develop, deploy, test and use what they need when they need it. These
capabilities include

* provisioning of the target nodes (baremetal nodes, libvirt VMs or instances
  on OpenStack depending on the scenario)
* installation of the stack with different compositions (platform, features,
  configurations)
* testing of the installed stacks

Apart from the basic capabilities, the framework makes it possible for developers
and users to deploy majority of the scenarios on their personal computers due
to conservative use of resources.

Please consult :ref:`User Guide <framework-user-guide>` to see how you can use the
framework.

Framework and CI/CD
===================

As noted in previous sections, the framework is heavily utilized by Nordix CI/CD
pipelines to deploy, test, and promote various scenarios. The idea with this
is that Nordix aims to do deployment and testing of various technologies
exactly the same way as its fellow contributers. So the framework is constantly
tested and verified.

How to Use This Documentation
=============================

The way we suggest you to use this documentation is actually trying things while
reading them.

* :ref:`User Guide <framework-user-guide>`: This is where the details of what is
  supported by the framework and steps to use it from most basic scenario to
  more complex ones.
* :ref:`CI/CD Guide <framework-cicd-guide>`: This guide describes cloud infra CI/CD
  pipelines which uses the framework. This could give you an idea about Nordix
  approach to CI/CD and what type and level of testing the framework is subject to.
  Apart from this, Nordix CI/CD is a working example of how to use the framework.
* :ref:`Developer Guide <framework-developer-guide>`: This is the most detailed guide
  which goes into the details of how to hack the framework in order to develop new
  features, fix bugs, and introduce new technologies.

Communication
=============

Cloud Infra Automation Framework is developed by Nordix Infra Team. The team uses
`Nordix Discuss Maillist <https://lists.nordix.org/mailman/listinfo/discuss>`_ so
if you experience any issues, we suggest you to send an email to the maillist,
describing the issue you face accompanied by any logs you can collect and put on
on paste sharing services such as `hastebin <https://hastebin.com/>`_ or
`pastebin <https://pastebin.com/>`_. Please make sure not to include any private
information such as passwords or SSH keys in the logs you upload to these services
since they are public and the private information you include unintentially can
be used for malicious purposes.
