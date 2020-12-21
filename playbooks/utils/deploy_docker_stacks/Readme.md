# Deploy Docker Stacks

This Util-Playbook is used to run the role `docker_stack` for all container stacks defined within host variable files as `docker_stacks`.

Example definition:

```yml
---

wp_db:      "wordpress"
wp_root_pw: "MyV3ry$ecre7R00tPW"
wp_dbuser:    "wp"
wp_dbpw:      "My$ecre7Us3rPW"

docker_stacks:

  wordpress:
    name:       "Wordpress"
    mariadb:    yes
    db_name:    "{{ wp_db }}"
    db_root_pw: "{{ wp_root_pw }}"
    db_user:    "{{ wp_dbuser }}"
    db_pw:      "{{ wp_dbpw }}"
    containers:
      - name: wordpress
        traefik: yes
        image: wordpress
        env:
          WORDPRESS_DB_HOST: "wordpress_mariadb:3306"
          WORDPRESS_DB_NAME: "{{ wp_db }}"
          WORDPRESS_DB_USER: "{{ wp_dbuser }}"
          WORDPRESS_DB_PASSWORD: "{{ wp_dbpw }}"
          WORDPRESS_TABLE_PREFIX: "wp_"
          WORDPRESS_DEBUG: "true"
        healthcheck:
          test: ["CMD", "curl", "-f", "http://localhost"]
          timeout: 30s
          retries: 10
        mountfiles_no_backup:
          - [[ "logs/debug.log", "/var/www/html/wp-content/debug.log" ]]
        directories:
          - [[ "wp-content", "/var/www/html/wp-content" ]]
        fqdn:
          - wordpress.domain.tld

...
```
