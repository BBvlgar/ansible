Prepare AWS SSM
===============

Prepares host for AWS SSM usage.

Requirements
------------
None.

Role Variables
--------------
None.

Dependencies
------------
None.

Aftercare
---------

You'll have to start and sign up every host for itself for SSM usage:

```sh
sudo amazon-ssm-agent -register -code "activation-code" -id "activation-id" -region "region"
sudo service amazon-ssm-agent start
```

Example Playbook
----------------
```
- name: add admin users
  hosts: servers
  become: true

  roles:
    - { role: prepare_aws_ssm }
```
