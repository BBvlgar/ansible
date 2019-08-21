AWS CLI
=========

Installs the AWS Command Line Interface via PIP.

Requirements
------------

* Ubuntu

Role Variables
--------------

### user

```
user: root
```
The user for which to install the config.

### region

```
region: eu-central-1
```
The AWS region used by the command line.

Dependencies
------------

None.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```
    - hosts: control-nodes
      roles:
         - awscli
```
