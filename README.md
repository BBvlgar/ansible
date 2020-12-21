# Ansible – Working-Repository

This repository is meant to be the working repository for the it-economics DevOps team.

## preparations

For the repository to be fully functional and able to communicate with its subtree repositories, one should add these additional remotes:

```sh
git remote add -f env_hosting ssh://git@git.it-economics.de:7999/in/env_hosting.git
git remote add -f env_production ssh://git@git.it-economics.de:7999/in/env_production.git
```

## directory structure

This repository contains these directories:

* `environments` – the parent directory of all environments. They can be added as `git subtree` to this repository – or simply be located there. By default, "new" ones are ignored. This directory is meant to be linked to from `ansible/environments`.
