# Firewall

With this role, we configure the `ufw` firewall.


## Requirements


## Role Variables

`global_ufw_rules` can be extended by the `host_ufw_rules` as a list. The elements out of these lists are dictionaries and have to consist out of `rule` and `port` key-value-pairs.

## Dependencies


## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yml
---

- hosts: 'all'

  tasks:

    - name: 'install and configure ufw'
      include_role:
        name: firewall
...
```


## License

BSD


## Author Information

Martin Winter <mwinter@it-economics.de>
