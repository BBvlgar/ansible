Install basics
===============

Installs basic tools to be present on every server.

Requirements
------------
None.

Role Variables
--------------
None.

Dependencies
------------
None.

Example Playbook
----------------
```
- name: add admin users
  hosts: servers
  become: true

  tasks:
    - name: 'update Raspy'
      include_role:
        name: install_basics
```
