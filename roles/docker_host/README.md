# `docker-host`

This role is to make the server, it is applied to, a Docker host, so it can run Docker containers.

## Requirements

Basic configuration of the server should be done.

## Role Variables

See `defaults/main.yml` for a brief overview.

## Dependencies

None.

## Example Playbook

Usage of this role within playbooks could look like that:

```yml
---

- hosts: 'all'

  tasks:

    - name: 'install docker tools'
      include_role:
        name: docker_host
...
```

## License

CC-BY

## Author Information

macwinnie <dev@macwinnie.me>
