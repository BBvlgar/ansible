# Docker Container Role

This role is meant to be the single point of managing docker containers through
Ansible to reduce the possible places of incidents with changes within Ansible
core. It is used i.e. within the `docker_stack` role.

## Annotations

This `docker_container` role is not completely representing _every_ parameter, that is provided by Ansible. It represents the ones, we need in daily business.  
If there is the need of another parameter, the role has to be updated!

[The latest Ansible documentation](https://docs.ansible.com/ansible/latest/modules/docker_container_module.html) provides a list of supported parameters (and instructions what the different parameters are used for). This is the current list supported by this role:

| Parameter | Default (in this role) | Variable to handle it | Variable types |
| --------- | ---------------------- | --------------------- | -------------- |
| `image`           | – | `{{ container.registry }}`, `{{ container.repository }}`, `{{ container.image }}`, `{{ container.version }}` | strings |
| `name`            | – | `{{ container.name }}` | string |
| `stop_timeout`    | `10` | `{{ container.stop_timeout }}` | integer |
| `hostname`        | `{{ container.name }}` | `{{ container.hostname }}` | string |
| `capabilities`    | `[]` | `{{ container.capabilities }}` | list |
| `state`           | `{{ cnt_state }}` | `{{ container.state }}` | string: `absent`, `present`, `stopped`, `started` |
| `env`             | `{}` | `{{ container.env }}` | dictionary |
| `recreate`        | `{{ cnt_recreate }}` | `{{ container.recreate }}` | string / boolean: `yes`, `no` |
| `exposed`         | `[]` | `{{ container.expose_ports }}` | list |
| `memory`          | `'0'` | `{{ container.memory_limit }}` | string |
| `log_driver`      | `json-file` | `{{ container.log_driver }}` | string |
| `log_options`     | `{}` | `{{ container.log_options }}` | dictionary |
| `networks`        | `[]` | `{{ container.networks }}` | list |
| `published_ports` | `[]` | `{{ container.aux_ports }}` | list |
| `volumes`         | `[]` | `{{ container.mountfiles }}`, `{{ container.directories }}` (both processed) and `{{ container.volumes }}` | list |
| `volumes_from`    | `[]` | `{{ container.volumes_from }}` | list |
| `restart_policy`  | `{{ docker_restart_policy }}` | `{{ container.restart_policy }}` | string: `no`, `on-failure`, `always`, `unless-stopped` |
| `labels`          | `{}` | `{{ container.labels }}` | dictionary |
| `user`            | `''` | `{{ container.user }}` | string |
| `privileged`      | `no` | `{{ container.privileged }}` | string / boolean: `yes`, `no` |
| `working_dir`     | `''` | `{{ container.working_dir }}` | string |
| `command`         | `''` | `{{ container.command }}` | string |
| `init`            | `no` | `{{ container.init }}` | string / boolean: `yes`, `no` |

## Variables used in this role

If variables are listed in the parameter table above but not below in the variable listing, please consider [the Ansible documentation](https://docs.ansible.com/ansible/latest/modules/docker_container_module.html)

### globally defined variables

* `docker_home` defines the location of the docker data, i.e. `/srv/` is often used
* `runallcontainer` can be used as `-e` env variable while a playbook run to ensure every container (really every one) contained within the playbook to be executed and created (new).
* `database_network` defaults to `database` and is the name of an only internally used Docker network to be used for inter-container-communication.
* `traefik_network` defaults to `proxy` and is the name of the network only the containers that are meant to communicate through the reverse proxy are connected for their communication with the specific container.
* `pull` can be used as `-e` env variable while a playbook run to ensure for every run container the actual newest image is pulled from registry. Defaults to `missing`.
* `cnt_state` tells a container, in which state it has to be for the role to execute successfully. It defaults to the value `started`.
* `cnt_recreate` defines if a container should be recreated if it already exists – defaults to `no`.
* `docker_restart_policy` defaults to `always`.

### specific role variables

The main variable has to be given as `container` variable to this playbook. This variable defines everything that should be taken care for building up one container – the variable is a dictionary:

* `container.name` this is the actual name of the docker container.
* `container.run` has the same effect as `{{ runallcontainer }}` above – but only for the container, the variable is defined for
* `container.pull` has the same effect as `{{ pull }}` above – but only for the container, the variable is defined for
* `container.registry` is optional to provide the domain of another registry than DockerHub with the port, it listens to – i.e. `my.registry.address:port`, no tailing slash!
* `container.repository` is optional and meant to define the repository the container image is located in (except one uses the library images of DockerHub).  
* `container.image` is mandatory and represents the actual image within the previous mentioned `{{ container.repository }}`
* `container.version` is optional and defaults to `latest`. It represents the tag that should be used for rollout with the current container.
* `container.shared_home_app` can be the name of another container the current container should place its Host bind files within the same parent folder – i.e. if the database of an app and the app itself have Host binds.  
If this variable is not set, `{{ container.name }}` is used as default – usage see below.
* `container.directories` is a list of lists that define all Host bind folders / directories.  
The lists within `{{ container.directories }}` consist out of 2 to 3 strings:
    * `container.directories.n.0` is the *relative* path that should be bound to the container – so finally it'll look like `{{ docker_home }}/{{ container.shared_home_app }}/{{ container.directories.n.0 }}/`
    * `container.directories.n.1` is the *absolute* path the `{{ container.directories.n.0 }}` should be bound to within the container
    * `container.directories.n.2` is optional and can be one value out of `ro`, `rw`, ...
* `container.mountfiles` is a list of lists. It is meant to define single (configuration) files to be bound to the container as Host bind and every contained list consists again out of multiple string:
    * `container.mountfiles.n.0` relative path from container folder on host
    * `container.mountfiles.n.1` absolute bind path within container
    * `container.mountfiles.n.2` optional bind permissions like `ro`, `rw`, ...
    * `container.mountfiles.n.3` optional file permissions – defaults to `0755`
* `container.docker_volumes` is a list of lists. It is meant to define single (configuration) files to be bound to the container as Host bind and every contained list consists again out of multiple strings:
    * `container.docker_volumes.n.name` name of the volume that should be created – identical name has to be used within `{{ container.volumes }}` to mount a folder from that volume.
    * `container.docker_volumes.n.state` optional and defaults to `present`, other possible value is `absent` for volume to be removed
* `container.volumes` is a list of strings representing regular binds with the format `absolute_path_on_host:container_path` or `absolute_path_on_host:container_path:permission` to bind / share i.e. the docker socks or `volume_name:container_path` for a volume mount (based on volumes defined by `{{ container.docker_volumes }}`!)
* `container.networks` is a list of dictionaries for networks, the container has to be added to.  
Networks are used to let the containers see each other by container name (which is `{{ container.name }}`).  
Ansible doesn't allow anything like "create if not already existing" – so when using networks there will almost every time be an ignored error, because a network already exists.
The dictionaries have – at the moment – only one key-value-pair:
    * `container.networks.n.name` defines the name of the network that will be created.
* `container.git` is a list of dictionaries that defines git repositories to be checked out on to the host.  
The single dictionaries within this list consist out of two entries:
    * `container.git.n.repo` is the repository, that should be checked out.  
    ATTENTION: this role doesn't handle permissions. Either the credentials have to be provided as basic auth parameters (`https://user:pass@server.git/repo` – the server has to support basic auth), the repo has to be accessible public (`https://server.git/repo`) or the executing user on the host has to have installed the proper deploy key for an ssl checkout (`ssh://git@server.git/repo`).
    * `container.git.n.dest` reflects the destination to which folder on the host the repository should be checked out to. It is again a relative path like in `{{ container.directories.n.0 }}`.  
    The destination should be reflected within the `{{ container.directories }}` variable to be bound to the container.
* `container.prepared_files` is a dictionary with two children.  
  The files will be copied, not moved through this role – a cleanup has to take part in the embedding roles / tasks!
    * `container.prepared_files.binds`
        * `container.prepared_files.binds.n.src` is the absolute path on the (remote) server where to find the relevant prepared file
        * `container.prepared_files.binds.n.dest` has to be an *RELATIVE PATH* to the application docker folder on top (see `container.directories`).
    * `container.prepared_files.mounts` is meant for copying prepared files, that are present on the server, to a specified location *AFTER* the container was created – the use case is, that one wants to copy templated files to a docker volume through the container.  
    This variable is again a list that has to be populated with dictionaries with two children:
        * `container.prepared_files.mounts.n.src` is the absolute path on the (remote) server where to find the relevant prepared file
        * `container.prepared_files.mounts.n.dest` has to be an *ABSOLUTE PATH* on the container, where the file should be copied to.

## Dependencies

## Example Playbook

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)


## Author Information

Martin Winter <mwinter@it-economics.de>
