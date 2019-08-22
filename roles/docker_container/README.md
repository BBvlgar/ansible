# Docker Container Role

This role is meant to be the single point of managing docker containers through
Ansible to reduce the possible places of incidents with changes within Ansible
core. It is used i.e. within the `docker_app` role.

## Annotations

This `docker_container` role is not completely representing _every_ parameter, that is provided by Ansible. It represents the ones, we need in daily business.  
If there is the need of another parameter, the role has to be updated!

[The latest Ansible documentation](https://docs.ansible.com/ansible/latest/modules/docker_container_module.html) provides a list of supported parameters (and instructions what the different parameters are used for). This is the current list supported by this role:

| Parameter | Default (in this role) | Variable to handle it | Variable types |
| --------- | ---------------------- | --------------------- | -------------- |
| `image`           | – | `{{ app.registry }}`, `{{ app.repository }}`, `{{ app.image }}`, `{{ app.version }}` | strings |
| `name`            | – | `{{ app.name }}` | string |
| `stop_timeout`    | `10` | `{{ app.stop_timeout }}` | integer |
| `hostname`        | `{{ app.name }}` | `{{ app.hostname }}` | string |
| `capabilities`    | `[]` | `{{ app.capabilities }}` | list |
| `state`           | `{{ cnt_state }}` | `{{ `app.state` }}` | string: `absent`, `present`, `stopped`, `started` |
| `env`             | `{}` | `{{ app.env }}` | dictionary |
| `recreate`        | `{{ cnt_recreate }}` | `{{ app.recreate }}` | string / boolean: `yes`, `no` |
| `exposed`         | `[]` | `{{ app.expose_ports }}` | list |
| `memory`          | `'0'` | `{{ app.memory_limit }}` | string |
| `log_driver`      | `json-file` | `{{ app.log_driver }}` | string |
| `log_options`     | `{}` | `{{ app.log_options }}` | dictionary |
| `networks`        | `[]` | `{{ app.networks }}` | list |
| `published_ports` | `[]` | `{{ app.aux_ports }}` | list |
| `volumes`         | `[]` | `{{ app.mountfiles }}`, `{{ app.directories }}` (both processed) and `{{ app.volumes }}` | list |
| `volumes_from`    | `[]` | `{{ app.volumes_from }}` | list |
| `restart_policy`  | `{{ docker_restart_policy }}` | `{{ app.restart_policy }}` | string: `no`, `on-failure`, `always`, `unless-stopped` |
| `labels`          | `{}` | `{{ app.labels }}` | dictionary |
| `user`            | `''` | `{{ app.user }}` | string |
| `privileged`      | `no` | `{{ app.privileged }}` | string / boolean: `yes`, `no` |
| `working_dir`     | `''` | `{{ app.working_dir }}` | string |
| `command`         | `''` | `{{ app.command }}` | string |
| `init`            | `no` | `{{ app.init }}` | string / boolean: `yes`, `no` |

## Variables used in this role

If variables are listed in the parameter table above but not below in the variable listing, please consider [the Ansible documentation](https://docs.ansible.com/ansible/latest/modules/docker_container_module.html)

### globally defined variables

* `docker_home` defines the location of the docker data, i.e. `/srv/` is often used
* `runallapps` can be used as `-e` env variable while a playbook run to ensure every container (really every one) contained within the playbook to be executed and created (new).
* `pull` can be used as `-e` env variable while a playbook run to ensure for every run container the actual newest image is pulled from registry. Defaults to `missing`.
* `cnt_state` tells a container, in which state it has to be for the role to execute successfully. It defaults to the value `started`.
* `cnt_recreate` defines if a container should be recreated if it already exists – defaults to `no`.
* `docker_restart_policy` defaults to `always`.

### specific role variables

The main variable has to be given as `app` variable to this playbook. This variable defines everything that should be taken care for building up one container – the variable is a dictionary:

* `app.name` this is the actual name of the docker container.
* `app.run` has the same effect as `{{ runallapps }}` above – but only for the container, the variable is defined for
* `app.pull` has the same effect as `{{ pull }}` above – but only for the container, the variable is defined for
* `app.registry` is optional to provide the domain of another registry than DockerHub with the port, it listens to – i.e. `my.registry.address:port`, no tailing slash!
* `app.repository` is optional and meant to define the repository the container image is located in (except one uses the library images of DockerHub).  
* `app.image` is mandatory and represents the actual image within the previous mentioned `{{ app.repository }}`
* `app.version` is optional and defaults to `latest`. It represents the tag that should be used for rollout with the current container.
* `app.shared_home_app` can be the name of another container the current container should place its Host bind files within the same parent folder – i.e. if the database of an app and the app itself have Host binds.  
If this variable is not set, `{{ app.name }}` is used as default – usage see below.
* `app.directories` is a list of lists that define all Host bind folders / directories.  
The lists within `{{ app.directories }}` consist out of 2 to 3 strings:
    * `app.directories.n.0` is the *relative* path that should be bound to the container – so finally it'll look like `{{ docker_home }}/{{ app.shared_home_app }}/{{ app.directories.n.0 }}/`
    * `app.directories.n.1` is the *absolute* path the `{{ app.directories.n.0 }}` should be bound to within the container
    * `app.directories.n.2` is optional and can be one value out of `ro`, `rw`, ...
* `app.mountfiles` is a list of lists. It is meant to define single (configuration) files to be bound to the container as Host bind and every contained list consists again out of multiple string:
    * `app.mountfiles.n.0` relative path from container folder on host
    * `app.mountfiles.n.1` absolute bind path within container
    * `app.mountfiles.n.2` optional bind permissions like `ro`, `rw`, ...
    * `app.mountfiles.n.3` optional file permissions – defaults to `0755`
* `app.docker_volumes` is a list of lists. It is meant to define single (configuration) files to be bound to the container as Host bind and every contained list consists again out of multiple strings:
    * `app.docker_volumes.n.name` name of the volume that should be created – identical name has to be used within `{{ app.volumes }}` to mount a folder from that volume.
    * `app.docker_volumes.n.state` optional and defaults to `present`, other possible value is `absent` for volume to be removed
* `app.volumes` is a list of strings representing regular binds with the format `absolute_path_on_host:container_path` or `absolute_path_on_host:container_path:permission` to bind / share i.e. the docker socks or `volume_name:container_path` for a volume mount (based on volumes defined by `{{ app.docker_volumes }}`!)
* `app.networks` is a list of dictionaries for networks, the container has to be added to.  
Networks are used to let the containers see each other by container name (which is `{{ app.name }}`).  
Ansible doesn't allow anything like "create if not already existing" – so when using networks there will almost every time be an ignored error, because a network already exists.
The dictionaries have – at the moment – only one key-value-pair:
    * `app.networks.n.name` defines the name of the network that will be created.
* `app.git` is a list of dictionaries that defines git repositories to be checked out on to the host.  
The single dictionaries within this list consist out of two entries:
    * `app.git.n.repo` is the repository, that should be checked out.  
    ATTENTION: this role doesn't handle permissions. Either the credentials have to be provided as basic auth parameters (`https://user:pass@server.git/repo` – the server has to support basic auth), the repo has to be accessible public (`https://server.git/repo`) or the executing user on the host has to have installed the proper deploy key for an ssl checkout (`ssh://git@server.git/repo`).
    * `app.git.n.dest` reflects the destination to which folder on the host the repository should be checked out to. It is again a relative path like in `{{ app.directories.n.0 }}`.  
    The destination should be reflected within the `{{ app.directories }}` variable to be bound to the container.

## Dependencies

## Example Playbook

## License

BSD


## Author Information

Martin Winter <mwinter@it-economics.de>
