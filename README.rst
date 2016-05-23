=========================================
Build Docker images of SaltStack formulas
=========================================

Trivial but working way to build docker images using existing SaltStack
formulas.

Quickstart
==========

Install docker, run ``./build.sh`` and see what will happen :-)

Images
======

salt-base
---------

Base image will setup packages repository, install Salt formulas and configure
Salt and Reclass so it's possible for per-service dockerfiles to execute salt
states.

Main idea behind using this base image is that it will ensure that your whole
infrastructure is built from the same version of formulas and metadata.

You can customize most of the things here:

- ``RECLASS_URL``

  - URL to git repository of your reclass structure

- ``RECLASS_BRANCH``
- ``REPO_URL``

  - APT repository with SaltStack formula packages

- ``REPO_COMPONENTS``

Per-formula
-----------

Per-service (aka per-formula) docker files are living in ``services``
directory, see ``services/postfix-server.dockerfile`` as an example.
