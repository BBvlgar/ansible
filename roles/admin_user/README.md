Admin User
=========                                                                                                                                      
Creates users specified in `admins` dictionary and grants admin, sudo and SSH public key access.
Fails when `admins` is not set.                      

Requirements                                            
------------
None.                                                              

Role Variables
--------------
### admins
```
admins:
  - name: alice
    pub_key: RSAPublicKey
    password: UnixPasswordHash

  - name: bob
    pub_key RSAPublicKey
    password: UnixPasswordHash
```
Where RSAPublicKey is created via ```ssh-keygen -t rsa```
and UnixPasswordHash via ```mkpasswd  -m sha-512  -s``` (needs package 'whois' on ubuntu)                    

### ssh_authorized_keys_dir
```
ssh_authorized_keys_dir: /etc/ssh/
```
The directory all SSH keys will be installed into and which is then read by sshd.

Dependencies
------------                                                               
None.

Example Playbook
----------------
```
- name: add admin users
  hosts: servers
  become: true

  roles:
    - { role: admin_user, admins: "{{ myAdminDictionary }}" }
```
