#!/bin/bash

function log() {
  echo $(date): $@
}

usage() {
    echo "Usage: integration.sh [options]"
    echo "  --user=USERNAME           The username for JIRA"      
    echo "  --password=PASSWORD       The password for JIRA"
    echo "  --debug                   Outputs debug information"
    exit 1
}

if [ -z $1 ] || [ -z $2 ] ; then
  usage
  exit 1
fi

# Parse arguments.
while [ $# -ge 1 ]; do
    case $1 in
        --help)
            usage
            ;;
        --user=?*)
          TICKET_USER=${1#--user=}
            ;;
        --password=?*)
          TICKET_PASSWORD=${1#--password=}
            ;;
        --debug)
            set -x
            ;;
        *)
            usage
            ;;
    esac
    shift
done

log "Ensure this script is started from the root of your ansible checkout"

log "Creating Docker container create_user"
LDAP_PORT=$(docker inspect --format '{{ (index (index .NetworkSettings.Ports "389/tcp") 0).HostPort }}' $(docker run -d -p 389 --name create_user iteconomics/create_user))

log "Give the container time to startup completely"
sleep 5

log "Running main.yml from create_user"
ansible-playbook -i environments/docker \
                  roles/create_user/tasks/main.yml \
                  -e "env=docker" \
                  -e "admin_user=admin" \
                  -e "admin_password=Def12345" \
                  -e "ticket_number=AM-36" \
                  -e "ticket_user=$TICKET_USER" \
                  -e "ticket_password=$TICKET_PASSWORD" \
                  -e "ldap_url=ldap://localhost:$LDAP_PORT" \
                  -e "no_log=false"
STATUS=$?

log "Cleaning up Docker container"
docker stop create_user
docker rm create_user

exit $STATUS
