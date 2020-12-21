# `ite_ssl`

Installs it-e SSL certificates on servers


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

    - name: 'install SSL certificates for it-e'
      include_role:
        name: ite_ssl
      vars:
        role_vars: "{{ environment_vars_for_this_role }}"
...
```


## License

BSD


## Author Information

Martin Winter <mwinter@it-economics.de>
