# Ansible Role: Mac App Store CLI (mas)

This Ansible Role is based on: https://github.com/geerlingguy/ansible-role-mas

Installs [mas](https://github.com/mas-cli/mas) via homebrew on macOS, and installs macOS apps from the Mac App Store.

## Requirements

  - **Homebrew**: Requires `homebrew` already installed 
  - **Mac App Store account**: Due to open issues you need to sign into Mac Appstore via Gui before or while running this role. Don't store unencrypted passwords with your playbooks!

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    appleid: ""
    appleid_password: ""

At the moment the automatic signin does not work and therefore is disabled.


    appstore_app_ids:
      - { id: 1451685025, name: "WireGuard" }
      - { id: 425424353, name: "The Unarchiver " }
      - { id: 409183694, name: "Keynote" }

A list of apps to ensure are installed on the computer. You can get IDs for all your existing installed apps with `mas list`, and you can search for IDs with `mas search [App Name]`. The `name` attribute is not authoritative and only used to provide better information in the playbook output.

    appstore_upgrade_all_apps: false

Whether to run `mas upgrade`, which will upgrade all installed Mac App Store apps.

## Dependencies

  - Homebrew must be installed

## Example Playbook

    - hosts: localhost
      vars:
        appstore_app_ids:
          - { id: 1451685025, name: "WireGuard" }
      roles:
        - brew-mas


## License

CC-BY

## Contribution

Linting with ansible-lint and yamllint is required


## Author Information

This role was was forked from https://github.com/geerlingguy/ansible-role-mas and is now maintained by Felix Kazuya.