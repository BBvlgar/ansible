# Docker Stack Role

This Role is meant to rollout web applications, that do not only consist out of
one container but are a stack of multiple containers and also should have
mounted directories from a (shared) data container and / or should have
additional containers in their stack like dedicated databases.

## Annotations

This role does not control docker containers. It prepares (complex) variable
structures and reuses the `docker_container` role to control them.

DNS settings are controlled by the separate `dns` role.

### Structure of web applications built by this role

1. The main application isn't meant to be reachable directly from the public
WorldWideWeb, it is meant to speak to the public through a reverse proxy. We
chose [Træfik](https://traefik.io/) for this purpose.  
Træfik is managed through the separate `docker_stack_traefik` role since this
role has to rely on it.
2. There is always one container hosting the main application. This could be
a `Jira`, `Confluence` or even an `Apache` hosting webapps like `LimeSurvey`.
3. For allowing *easy* backups without going through *every single* Docker
container, we create a `data` container for every stack. This container can be
used for simple scripts to mount all volumes in a backup container, etc.
4. Every stack can contain additional containers. These are managed within a
dictionary structure provided to this role.  
There are two additionals that are predefined with this role:
    * a `mysql` container, that is based on the official `mysql:5.6` image and
    configured like we need it in regular setups.  
    It can be toggled by setting `stack.mysql` to `true`.
    * a `postgres` container, that is based on the official `postgres:9.6`
    image and is configured along our regular needs.  
    It can be toggled by setting `stack.postgres` to `true`.

## Variables used in this role

### Binds and Mounts

* `directories`, `mountfiles` and `volumes` exist for each container.
* if the item should not be prepared for Backup within the data container, the keys should be appended with `_no_backup`, so `directories` become `directories_no_backup`.

### globally defined variables

* `database_network` defaults to `database` and is the name of an only
internally used Docker network to be used for inter-container-communication.
* `traefik_network` defaults to `proxy` and is the name of the network only the
containers that are meant to communicate through the reverse proxy are connected
for their communication with the specific container.
* `postgres_version` defaults to `9.6`, defines the version of Postgres to be
used for the `postgres` container.
* `mysql_version` defaults to `5.6`, defines the version of MySQL to be used for
the `mysql` container.
* `template_destination` defines the location where this role puts filled
templates. These templates will be moved by `docker_container` role to specific
container folders.

### specific role variables

The main variable has to be given as `stack` dictionary to this playbook. This
variable defines everything that should be taken care for building up the docker
stack out of multiple containers.  
The dictionary is structured like this:

* `stack.name` defines the name of the main application and the base name of the
stack.  
If the value i.e. is `portainer`, there is always a `data` container within the
stack, so this one will be named `portainer_data`. With all other containers
belonging to the stack it'll be the same schema.
* `stack.mysql` toggles the creation of a `MySQL` container via values `true` or
`false` (default: `false`)  
* `stack.postgres` toggles the creation of a `Postgres` container via values
`true` or `false` (default: `false`)
* `stack.db_name` defines the MySQL / PostgreSQL database one wants to work with.
* `stack.db_user` defines the MySQL / PostgreSQL user to work with.
* `stack.db_pw` defines the MySQL / PostgreSQL password for the dedicated user above.
* `stack.db_root_pw` defines the password for MySQL root user (unused with PostgreSQL).

If you want to two or all three of MySQL, MariaDB or PostgreSQL with different settings, you can replace `db_` within the variables above by `mysql_`, `mdb_` or `pg_` – so i.e. `stack.db_name` gets `stack.pg_name` with PostgreSQL.

## Dependencies

* `docker_container` role since it is used to deploy each single container
* `docker_stack_traefik` role since that deploys the Træfik container

## Example Playbook

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)

## Author Information

macwinnie <dev@macwinnie.me>
