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

### ENV Variables to change run of role

| Variable        | Description |
| --------------- | ----------- |
| `install_ufw`   | Defaults to `true` and determines if the `ufw` tool should be installed |
| `configure_ufw` | Defaults to `true` and determines if the configuration of `ufw` should be deployed |
| `restart_ufw`   | Defaults to `true` and determines if the `ufw` service should be restarted to apply configuration changes |
| `enable_ufw`    | Defaults to `true` and determines if the `ufw` service should be enabled to take effect |

## License

CC-BY

## Author Information

macwinnie <dev@macwinnie.me>
