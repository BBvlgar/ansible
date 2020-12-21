# `ssh_server`

Provision a host as SSH host.


## Requirements

None.

## Role Variables


## Dependencies

None.

## Example Playbook


```yml
---

- hosts: 'all'

  tasks:

    - name: 'install host as SSH host'
      include_role:
        name: ssh_server
...
```


## License

BSD


## Author Information

Martin Winter <mwinter@it-economics.de>
