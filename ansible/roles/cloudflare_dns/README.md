# Cloudflare DNS

Set Cloudflare DNS

## Requirements

CNAME DNS should not be set.

This role is supposed to be called within other roles – and requires some variables from the `docker_app` role:

* `app.hostname`
* `traefik_fqdn`

## Role Variables

* `cloudflare_api_token`
* `cloudflare_email`

## Dependencies

The `docker_app` role is required as parent role.

## License

CC-BY

## Author Information

macwinnie <dev@macwinnie.me>
