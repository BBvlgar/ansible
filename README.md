# License
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

# Authors
- macwinnie <dev@macwinnie.me>
- Felix Kazuya <dev@felixkazuya.de>

# Ansible
Infrastructure as Code repository – a basic repository to build custom environments from.

## Thoughts

This Ansible repository holds everything to run – but no sensitive data. This
core repository is meant to be imported into a combination / working repository,
e.g. as Git subtree (see below).

The base structure of this repository consists out of nested directories and some
symlinks, that allow us to structure our infrastructure as code.

```
.
├── certs          # symlink to ../certs – to be provisioned within embedding repo
├── custom_files   # symlink to ../custom/files – to be provisioned within embedding repo
├── environments   # symlink to ../environments – to be provisioned within embedding repo
├── playbooks
│   ├── apps
│   ├── server
│   └── utils
├── roles
└── templates

```

Where `certs` as storage for server certificates and `templates` as storage for
(reusable) templates for example to be used for configurations have helping
structure character, the `roles` directory contains reusable playbooks,
that also accept parameters from playbooks calling them – the typical Ansible
roles.

`custom_files` is used to provide files to ansible roles like `nagios_client`,
that are group- or host- but at least organisation-specific.

Further all specific playbooks – for initialising a new server, updating one or
deploying a specific application – should be sorted into the category folders
within the `playbooks` directory. We differentiate between `apps` (typical
applications like a confluence or survey app), `server` for specific server
playbooks and `utils` for helping playbooks like the `updateAll` play.

The environments are meant to host one subfolder for each deployment
environment. `production` and `testing` environments are the recommended ones.

Every environment consists of three structure elements basically: the
`group_vars` directory, the `host_vars` directory and an `inventory.yml` file,
that contains all (default) server definitions for an environment.

This basic structure leads to minimal `include` / `import` structures within the
playbooks and roles since there is a policy of overriding (autoloaded) defaults:

`runtime` > `host_vars` > `group_vars` > `role defaults` (where `>` has its math. meaning)

See also [the ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)

### The subtree construct

For the ability to devide Ansible code from sensitive data like environments, we
decided to use Git subtree. Therefor, we have multiple repositories:

* This `ansible` repo for the Ansible files
* `env_x` repositories for each environment may be possible
* A `combined` repo, that combines all these repos into one working repo

The `combined` repo also holds the `certs` folder mentioned before.


### The `inventory.yml` file (or simply `inventory`)

Since there are situations, where we do not define DNS entries of hosts, we
define an aditional variable within our inventory file, the `alias_fqdn` on
which we can fall back on if the hostname defined in `ansible_host` variable
is an IP address. For that, we realize it the other way round: if `alias_fqdn`
is not defined, we'll use the `ansible_host` as default fallback.

The variable `ansible_hostname` or `inventory_hostname` will mostly represent
the host alias.

After these thoughts, we'll have a look on the general structure of the
inventory.

First of all, we'll have to define a list of all servers with their host specific
variables and information.  
After that, we'll group these servers to get meaningful elements for running the
playbooks on, for example to define the admin and SSH users on them to be installed.

So the file should look like this:

```yml
[server_definitions]
short_alias     ansible_user=login    ansible_port=22   ansible_host=fqdn_or_ip   alias_fqdn=fqdn_if_ip_on_host

[regular_admins]
short_alias
```

## Requirements

@ToDo

### Encryption

Secrets can be encrypted by [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
or by [git-crypt](https://github.com/AGWA/git-crypt).

For the working repository, we hardly recommend to use any of those methods
to protect the load of sensitive information needed for running Ansible.

Since this shared repository must not contain any secrets, we don't use any
encryption method directly here. But since as stated above, the sensitive data
of the working repository should not be read by any third-party user (especially
(database) passwords).

If you use `git-crpyt`, some preparations are already bundled with this shared repo.

To unlock all files in the main repository, your GPG key has to be in the
decryption keys or you have to know the static decryption key.

All encryptions are defined within the `.gitattributes` files.

The types of files, that are globally defined to be encrypted (like `*.crt`,
`*_rsa*`, and so on), are defined within the one within the repository root.

Since the recursivity of such definitionfiles doesn't allow nested wildcards,
we have to place a `.gitattributes` file within each `group_vars` folder of
every environtment with the following content:

```
all.yml   filter=git-crypt diff=git-crypt
```

That is for the `all.yml` file has to be encrypted since there will be passwords
and keys located.

Along special file types like `*.crt*`, `*_rsa*`, etc only one varibale file for
each environment is wanted to be encrypted: the `all.yml` group vars file.
That's for pull requests and repository development beeing more transparent.



## Usage

@ToDo
