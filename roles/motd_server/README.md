# Server `motd` – Message of the day

This role is meant to provision servers with messages of the days.

## Variables used within this role

* `package_state` – defaults to `latest` and should not be changed.
* `motd_basic_tools` – this is the variable holding the default toolset list to be installed in order to use this `motd` role. This list consists out of mutliple dictionaries – mandatory key-value key is `name` to define the package; optional kv key `state` defaulting to `latest` (see `package_state`). If you want to modify the toolset for your `motd`, you can extend it by defining `custom_motd_tools` variable and / or overriding the `motd_basic_tools` variable.
* `backup_motd` – if set to `True` / `yes`, a backup of the existing motd files will be created.
* `backup_destination` – define a destination for your `motd` backup if you activate it.
* `remove_existing_motd` – if set to a true value, all existing motd files will be deleted and replaced by the motd templates
* `remove_motd` – list of motd files that should be removed
* `motd_templates` – that's the dictionary of `motd` templates to be pushed to `/etc/update-motd.d/`. Refer to the [documentation](http://manpages.ubuntu.com/manpages/focal/man5/update-motd.5.html) on how the scripts have to be designed. Keys of the dictionary are used as file names, block content will be script content. By default, there is pushed one `00-00header` script – see below. If you want to modify / add motds, you have to re-define that dictionary.

## default `00-00header` by this script

This role comes with one additional motd by default – and every other motd stays in place by default. That motd is defined by this script:

```sh
#!/usr/bin/env bash

export LANG="en_US.UTF-8"

printf "\n"
figlet "{{ motd_servername | default( "$( hostname | sed 's/\w\+/\L\u&/g' )" ) }}" | /usr/games/lolcat -f

{% if motd_organisation is defined and motd_organisation != '' %}
printf "\n"
figlet -fsmall "{{ motd_organisation }}" | /usr/games/lolcat -f
{% endif %}

{% if motd_unicorn_description is defined and motd_unicorn_description != '' %}
printf "\n"
motd_server_description="{{ motd_unicorn_description }}"
folded_description="$( fold -w {{ unicorn_max_len | default( 30 ) }} -s <<< "${motd_server_description}" )"
boxes -a c -d unicornthink <<< "${folded_description}" | /usr/games/lolcat -f
{% endif %}

{% if motd_description is defined and motd_description != '' %}
printf "\n"
motd_server_description="{{ motd_description }}"
folded_description="$( fold -w {{ description_max_len | default( 80 ) }} -s <<< "${motd_server_description}" )"
echo "${folded_description}"
{% endif %}

```

This default template is working with some (host) variables, you could / should set (all of them are optional):

* `motd_servername` is optional – it will default to the hostname of the host with capitalized first letter
* `motd_organisation` is to define a string identifying your organisation
* `motd_unicorn_description` will be printed out by a unicorn [ASCII-box](https://boxes.thomasjensen.com) – the default line length is 30 and may be adjusted by the variable `unicorn_max_len`
* an alternative to `motd_unicorn_description` may be `motd_description`, which simply echoes the given description folded by a default length of 80 what may be adjusted by `description_max_len`


## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)


## Author Information

Martin Winter <mwinter@it-economics.de>
