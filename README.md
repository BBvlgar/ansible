# Ansible – working repository

This repository is meant to be the working repository for the it-economics DevOps team.

## directory structure

This repository contains these directories:

* `ansible` – here the main Ansible content is located; `ansible-playbook` commands have to be executed here.
* `environments` – the parent directory of all environments. They can be added as `git subtree` to this repository – or simply be located there. By default, "new" ones are ignored. This directory is meant to be linked to from `ansible/environments`.
* `certs` – directory custom certificates. This directory is meant to be linked to from `ansible/certs`.

## working with the subtree remotes

ATTENTION: only to be performed, if you know what you are doing ;)

### preparations

For the repository to be fully functional and able to communicate with its subtree repositories, one should add these additional remotes:

```sh
git remote add -f ansible ssh://git@git.it-economics.de:7999/in/ansible.git
git remote add -f env_hosting ssh://git@git.it-economics.de:7999/in/env_hosting.git
git remote add -f env_production ssh://git@git.it-economics.de:7999/in/env_production.git
```

### fetching changes from the remotes into working repo

If the central repositories changed – for example by third-party contribution – we can fetch these contents (with the remotes defined) like this:

```sh
git fetch --all
git subtree pull --prefix ansible ansible master
git subtree pull --prefix environments/production env_production master
git subtree pull --prefix environments/hosting env_hosting master
```

### merge back into dedicated repositories

When changes are finalized within the working repository, they should also be regularly merged back into the dedicated repositories. That can be done by these comments:

```sh
git subtree push --prefix=environments/hosting env_hosting master --squash
git subtree push --prefix=environments/production env_production master --squash
git subtree push --prefix=ansible ansible master --squash
```
