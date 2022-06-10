# Ansible – working repository DevOps it-economics GmbH

This repository contains all configuration information for restore the (Linux) servers of it-economics GmbH. It is so colled “infrastructure as code”. You'll find mutliple other repositories included within this one – how that works and what usecase that is for, you'll find described within this `README.md`.

## Structure of the repository

At the root of the repo, you find this `README.md`. Aside of it, there are three relevant directories: `ansible`, `certs`, `custom` and `environments`:

* `ansible` is the Git subtree containing the core Ansible structure. From this directory as a root, you'll call your playbooks defining your servers. **The core is published as open source**, so be aware of not publishing company secrets within there. _Secrets are handled below at a separate point._
* Since it-economics has some long-running certificates for servers / services, you'll find these within the `certs` directory. This one is linked into the root of `ansible`.
* `custom` is the parent of additional things, that should not be available within the `ansible` core. So for example, our **it-e internal** playbooks, that can be run from `ansible` root by calling them as `playbooks/custom/play.yml` are located within `custom/playbooks`.  
_These directories will be improved and expanded by time._
* `environments` is the location of all environments. They are the one and only location for defining the infrastructure by group variables, host variables and especially the `inventory.yml` that defines all known servers. This directory is also linked directly into the root of `ansible`.  
**By default, every new environment will be ignored by git, so you'll need to force the git add. That is for you to be able to define your own testing environments without publishing them to everyone else.**

## System requirements

Your system, from which you'll regularly run `Ansible` should be a Unix system – so MacOS or Linux. Within it-e, we'll use the `Admin Mac` in general. The System has to be installed along [the documentation](http://docs.ansible.com/ansible/latest/intro_installation.html).

Since this repository also contains confidential information like secrets or passwords, we protect them against unauthorized access by using [Git-Crypt](https://github.com/AGWA/git-crypt/blob/master/README.md), which relies on `GPG` encryption.

So for being able to work with this repository, you've to install `Ansible`, `GPG` and `git-crypt` on the local machine.

### Unlocking of the git-crypt locked secrets

The unlocking will be executed automatically while executing the Ansible playbook – that's the cause for the `plugins/vars_plugins/git-crypt.py` file within the `ansible` core repo.  
Still, **it is recommended** to unlock the repository manually.

Once unlocked all further locking (`git push`) or unlocking (`git pull`) is done automatically.

To unlock, there are two methods:

#### Your personal GPG key

That method is meant to be the standard way. The user has to have a [GPG-Key](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/generating-a-new-gpg-key) – preferably linked with the company email address.

As of the key being public (e.g. through the [public key server of OpenGPG](https://keys.openpgp.org/) – Key-Server URL `hkps://keys.openpgp.org`), it can be added to the unlocked repository as authorized to also unlock it by this command:

```sh
# replace USER_ID by email address or ID!
git-crypt add-gpg-user USER_ID
```

As of the repository being published (`git push`) from now, the new user also can decrypt the repository by using `git-crypt unlock` if the **GPG private key** is available on the executing machine.

For removing the permissions for users – [as of January 2021](https://github.com/AGWA/git-crypt/issues/47) – there has to be created a new Key at first. And in another step, all remaining users have to be added again to be allowed to unlock the new key. If that is performed, also the encrypted secrets should be renewed (and probably the Git history cleaned up) since the old keys can still unlock old Git states.

#### The static key file

This method is not meant to be the default way. **Be also aware of this section, if GPG users are removed!**

For “emergency” cases, it can be helpfull to store the static key as Base64 encoded string e.g. within a password safe. When the repository is unlocked, one can generate that string by this command on the CLI within the root of this repository:

```sh
git-crypt export-key /dev/stdout | base64
```

Unlocking with that Base64 string works as the following:

```sh
echo "WW91IG5lZWQgeW91ciB2YWxpZCBrZXkgc3RyaW5nIQo=" | base64 -d | git-crypt unlock /dev/stdin
```

*(Be aware of replacing `WW91IG5lZWQgeW91ciB2YWxpZCBrZXkgc3RyaW5nIQo=` by the correct key string!)*

For the unlocking through the run of Ansible playbook, it is necessary to place this Base64 key as file on the local system. the absolute path of that file has to be exported to the executing Shell as [ENV variable](https://www.digitalocean.com/community/tutorials/how-to-read-and-set-environmental-and-shell-variables-on-linux#creating-environmental-variables), e.g. by running `export GITCRYPT_KEY_PATH='/path/to/keyfile'`.

## Environments

There are multiple environments – the main environment is `production`, so this `README.md` will only have a look on that.

An Ansible environment basically consists out of three entities:

* the inventory – `/environments/production/inventory.yml`
* the group variables – `/environments/production/group_vars/*`
* the host variables – `/environments/production/host_vars/*`

Within an Ansible environment, all relevant information for the hosts are located. Especially the (encrypted) secrets.

### Inventory

The inventory list that contains every server to be managed by Ansible. Every row matches one instance.

Rows embraced by square brackets define groups – here are the relevant ones out of our environment:

* `[all]` list of all servers – equals to the children of `[server_definitions]`.
* `[server_definitions]` – our definition group ... see below for details
* `[updatableServers]` – explicit list of servers to be updated by update playbook
* `[docker_host]` – explicit list of servers that should work as Docker hosts
* `[raspi]` – list of defined Raspberry Pi computerso

All groups could contain complete server definitions. In order to keep the overview of all instances, the `[server_definitions]` group exists. **As a convetion**, this group is the _single_ group to define server definitions. All other groups only reference other groups (via the `[groupname:children]` tag of the group) or server alias (below e.g. `server_alias`).

An example definition within the `[server_definitions]` group could look like that:

```
[server_definitions]
server_alias   ansible_port=22   ansible_user=root   ansible_host=192.168.1.234   alias_fqdn=example.server.tld
```

* `server_alias` the shortname to be used everywhere in Ansible
* `ansible_port` the SSH port to be used for that instance
* `ansible_user` a default user – to be overridden in our setup almost everywhere
* `ansible_host` either an IP address or the [FQDN](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) of the server
* `alias_fqdn` **optional** – if `ansible_host` cannot be the FQDN, but a playbook wants to use it e.g to define the Hostname, this variable can be used to define it as an alias

The `server_alias` will be used in all other group definitions or to limit the scope of the `ansible-playbook` commands. Usage in groups could look like that:

```
[group]
server_alias
another_server
```

### Variables

For both, group and host variables, either single `entity.yml` YAML definition files or directories `entity` with multiple YAML definition files `entity/xx-description.yml` can define the context. `entity` is either the groupname (`[entity]` within the inventory) or the server alias like above.

#### Group variables

All applicable attributes for the respective group are defined in the folders beneath `/environments/production/group_vars`.

#### Host variables

The same as for group variables also applies to host variables beneath `/environments/production/host_vars`.

#### Validity

If variables are defined on different levels – e.g. within group and host variables – they will be used in [defined order](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#understanding-variable-precedence) and probably overriden. The basic rule is that host variables always overwrite group variables.

## Ansible commands

You have to execute Ansible playbooks on your terminal / CLI from `ansible` directory, not the repository root where this `README.md` can be found.

Even though there are multiple scripts and configurations – e.g. roles, templates, ... – the only relevant and executable objects are so called **playbooks**.

To run such a playbook, this command can be an orientation:

```sh
ansible-playbook -e ansible_user=USER -i environments/production -K --limit what_to_limit playbooks/your/playbook.yml
```

## adding new SSH users

Within our `production` environment, SSH users are defined within the `/environments/production/group_vars/all/00_users.yml` file. There, the public SSH key of the user (`pub_key`) and a password hash of their user password (`password`) has to be defined:

```yml
admins:
  - name: "alice"
    comment: "Full Name, E-Mail"
    pub_key: "RSAPublicKey"
    password: "UnixPasswordHash" | not set ""

  - name: "bob"
    comment: "Full Name, E-Mail"
    pub_key: "RSAPublicKey"
    password: "UnixPasswordHash" | not set ""
...
```

The value `RSAPublicKey` can be generated on the local machine of the user by:

```sh
ssh-keygen -t rsa
```

and the `UnixPasswordHash` should be generated by this command:

```sh
mkpasswd -m sha-512 -s
```

The user rollout takes place by running the `rollout_users` playbook below `utils` and also with the first installation playbook `first_install` also below `utils`.

## The lazy admin

To reduce the command length, we've defined some simplifications on our central Admin Mac, that are described below

### Secrets

Secrets should not be kept readable – especially not on shared systems like the Admin Mac. To protect our secrets from other admins / users, we create a DES3 encrypted secrets file. The needed information for the global alias can be created by the following commands:

```sh
cat <<EOF > ~/secretfile
export SUDO_PW='SUDO_PW'
export LDAP_PW='LDAP_PW'
export OFFICE_PW='OFF_PW'
export TMMITTELSTAND_PW='TMM_PW'
export API_TOKEN='API_TOKEN'

## one of the following is needed =)
# export OFFICE_FA_METHOD='PopUp'
export OFFICE_FA_METHOD='Code'

EOF
```

When you've created your `~/secretfile` either on the server or on your local machine, you want to edit the secrets. Therefor use `vim ~/secretfile` or `nano ~/secretfile`.

Afterwards, the secrets file is not encrypted but plain text. So we need to execute the following commands – do not combine them into one!

```sh
openssl des3 -salt -in ~/secretfile -out ~/credentials.des3
```

```sh
rm -f ~/secretfile
```

_You'll be asked for a password. That password will be needed **at every login** on the CLI to decrypt your secrets!_

### Decrypting the secrets

The magic behind the recently created `~/credentials.des3` file is to unlock it on every login on the CLI. Therefor in a profile file (e.g. the personal ones `~/.zprofile`, `~/.zshrc`, `~/.profile` or `~/.bash_rc` or even the global ones `/etc/bashrc`, `/etc/profile`, `/etc/zshrc` or `/etc/zprofile`) this little script can be placed. On our Admin Mac, the relevant profile file is `/etc/zshrc`.

```sh
###
#
#  CREDENTIALS DES3
#
###
#
#  To use the following part, ensure there is a file `~/credentials.des3` within
#  your home directory.
#  The contents of that file should be encrypted by DES3 with this command:
#
#     openssl des3 -salt -in ~/secretfile -out ~/credentials.des3
#
#  Don't forget to delete the plain text file `secretfile`!
#
#  The contents should i.e. export credentials variables, what could look like that:
#
#     export SUDO_PW='$up3rSecure!'
#
###

des3file="$(eval echo "~$(whoami)")/credentials.des3"
if [ -f "${des3file}" ]; then

    # Helping the Sourcetree Terminal opener not to die ...
    run=1
    while [ ${run} -eq 1 ]; do
        echo "Decrypt Password for des3 file:"
        read -s decryptpass
        if [[ ${decryptpass} =~ ^cd.*\&\&\ clear$ ]]; then
            eval ${decryptpass}
        else
            run=0
        fi
    done

    if [ ! -z ${decryptpass} ]; then
        decrypted="$(openssl des3 -d -salt -in "${des3file}" -k ${decryptpass})"
        if [ "$?" -eq "0" ]; then
            echo "${decrypted}" | while IFS= read -r line; do eval "${line}"; done
        fi
    fi
fi
```

### Usage of the secrets

On Admin Mac, we defined within our global `/etc/zshrc` for all users:

```sh
###
#  ANSIBLE Alias
###

# if all mandatory variables are set, configure the alias
if [ ! -z ${TMMITTELSTAND_PW+x} ] && [ ! -z ${SUDO_PW+x} ] && [ ! -z ${LDAP_PW+x} ]; then

    ansibleDirectory='~/git/devops/ansible/'

    alias prod-ansible-playbook='ansible-playbook -e "ticket_user=$(whoami) env=production ansible_sudo_pass=${SUDO_PW} admin_user=$(whoami)  admin_password=${LDAP_PW} admin_api_token=${API_TOKEN} ticket_password=${LDAP_PW} tmmittelstand_user=ASM00413\\$(whoami) tmmittelstand_password=${TMMITTELSTAND_PW} ANSIBLE_DEBUG=1"'

    alias ite-create="cd ${ansibleDirectory} && prod-ansible-playbook -i environments/production playbooks/custom/create_user/tasks/main.yml"
    alias ite-update="cd ${ansibleDirectory} && prod-ansible-playbook  -e override_user=true -i environments/production playbooks/utils/update_all_servers/main.yml"

    # if OFFICE_PW or OFFICE_FA_METHOD not set, do not define them within the following alias
    if [ -z ${OFFICE_PW+x} ] || [ -z ${OFFICE_FA_METHOD+x} ]; then
        alias ite-delete="cd ${ansibleDirectory} && prod-ansible-playbook -e "office_user=$(whoami)@it-economics.de" -i environments/production playbooks/custom/delete_user/tasks/main.yml"
    else
        alias ite-delete="cd ${ansibleDirectory} && prod-ansible-playbook -e "\""office_user=$(whoami)@it-economics.de office_password=${OFFICE_PASSWORD} office_2fa_method=${OFFICE_FA_METHOD}"\"" -i environments/production playbooks/custom/delete_user/tasks/main.yml"
    fi
fi
```

For that, the ansible commands can be shortened actually to `ite-delete`, `ite-create`, etc ...

**ATTENTION**:
This _WARNING_ is really relevant!  
Since your `sudo` password (and others) are now passed in plain text to Ansible by usage of these alias, you do **NEVER** want to use the verbose mode `-vvv` or even `-vvvv` if you are not allone or you are observed / observable. Otherwise, third parties can view your passwords!


## Git Subtree

**ATTENTION:**
For the following changes, you need to know, how the commands change the repository and so what you are doing. =)

When changes are finalized within the working repository, it-economics can contribute to the OpenSource shared part. The GitHub users have to be authorized team members of `devops-ansible`:

### preparations

For the repository to be fully functional and able to communicate with its subtree repositories, one has to add these additional remotes:

```sh
git remote add -f ansible https://github.com/devops-ansible/ansible.git
```

### fetching changes from the remotes into working repo

If the central repositories changed – for example by third-party contribution – we can fetch these contents (with the remotes defined) like this:

```sh
git fetch --all
git subtree pull --prefix ansible ansible master --squash
```

### merge back into dedicated repositories

When changes are finalized within the working repository, they should also be regularly merged back into the dedicated repositories. That can be done by these comments:

```sh
git subtree push --prefix ansible ansible master --squash
```

### adding completely new remotes and subtrees

When you want to add another subtree, the first step is again to add the new remote, then add the repository in place and push your (local) changes back to this repository.

**As a convention**, we start adding new subtrees by the documentation within this `README.md`. So add it in place above with all relevant steps, commit the change in `README.md` in preparation of your afterward changes and _then_ execute your commands to publish the new subtree.

Also as a convention, we name our remotes in [snake case](https://en.wikipedia.org/wiki/Snake_case).

For logic reasons, the `ansible` remote should be the first to be pulled, but the last to be pushed to.

While adding a new remote, the `-f` in the command above is strongly recommended – since that command will perform the instant fetch of the Git history, so you can proceed instantly.

After adding a new remote – e.g. `demo_remote`, that should be located after everything at the base root of the repository as the directory `demo/repository` – add the subtree with this command:

```sh
git subtree add --prefix demo/repository demo_remote master
```

Do not forget to push the current state of the main repository back to the remote Git server!

### Nice to know

Wihtin every `git subtree` command above, you can change some things like

* `master` to any branch name of the (subtree) remote, so if you want to persist the `dev` branch of e.g. an `env_testing` remote at `environments/testing`, simply use `git subtree ... --prefix=environments/testing env_testing dev`
* add the `--squash` option at the end fo the command, if you do not want to attach the whole history but only the current state of the remote code. **But beware**: mixing up squashed and unsquashed commits can result in `unrelated histories`! ... Then you normally need to squash ... always ... =D
