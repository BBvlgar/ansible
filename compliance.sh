ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/rollout_users/main.yml --limit "updatableAWSServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/ensure_standards/main.yml --limit "updatableAWSServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks playbooks/utils/create_and_rollout_with_compose/main.yml --limit "updatableAWSServers"

ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/rollout_users/main.yml --limit "updatableHetznerRootServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/ensure_standards/main.yml --limit "updatableHetznerRootServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks playbooks/utils/create_and_rollout_with_compose/main.yml --limit "updatableHetznerRootServers"

ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/rollout_users/main.yml --limit "updatableAWSServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/ensure_standards/main.yml --limit "updatableAWSServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks playbooks/utils/create_and_rollout_with_compose/main.yml --limit "updatableAWSServers"

ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/rollout_users/main.yml --limit "updatableHetznerCloudServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/ensure_standards/main.yml --limit "updatableHetznerCloudServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks playbooks/utils/create_and_rollout_with_compose/main.yml --limit "updatableHetznerCloudServers"

ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/rollout_users/main.yml --limit "updatableInternalServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks/utils/ensure_standards/main.yml --limit "updatableInternalServers"
#ansible-playbook -e "env=production override_user=true"  -i environments/production playbooks playbooks/utils/create_and_rollout_with_compose/main.yml --limit "updatableInternalServers"

echo "now setting master AMI ID for Hosting"

echo "now setting master AMI ID for Infra"


