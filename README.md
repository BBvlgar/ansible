# Ansible

Infrastructure as Code repository – a basic repository to build custom environments from.

## Thoughts

The base structure of this repository consists out of 17 (nested) directories,
that allow us to structure our infrastructure as code.

```
.
├── certs
├── environments
│   ├── hosting
│   │   ├── group_vars
│   │   └── host_vars
│   ├── production
│   │   ├── group_vars
│   │   └── host_vars
│   └── testing
│       ├── group_vars
│       └── host_vars
├── playbooks
│   ├── apps
│   ├── server
│   └── utils
├── roles
└── templates

17 directories
```

Where `certs` as storage for server certificates and `templates` as storage for
(reusable) templates for example to be used for configurations have helping
structure character, the `roles` directory should contain reusable playbooks,
that also accept parameters from playbooks calling them – the typical Ansible
roles.

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

`runtime` > `host_vars` > `group_vars` > `role defaults`

See also [the ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)

## Requirements

@ToDo

### Encryption

Since with this repository loads of sensitive information is stored, that should
not be read by any user (especially (database) passwords), some files in this
repository are encrypted by the git add-on `git-crypt`, which his to be
installed on your machine.

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
