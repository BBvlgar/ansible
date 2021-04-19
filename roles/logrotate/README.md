Basic usage example:

```yaml

logrotate:
  traefik:
    logfile: '/mnt/shared/applications/traefik.website/logs/traefik.log'
    time:       'weekly'
    rotate:     '5'
  mosh_ufw.log:
    logfile: '/var/log/mosh_ufw.log'
    time: 'weekly'
    rotate: '5'
```

The example above will create the logrotate config files `/etc/logrotate.d/traefik` and `/etc/logrotate.d/mosh_ufw`.
