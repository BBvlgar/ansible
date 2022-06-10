# Requirements
* AWS Account with running host amibuilder (Ubuntu 14.04), matching elastic ip (see inventory) and IAM Role
```
 {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:Describe*",
                "ec2:CreateSnapshot",
                "ec2:CreateImage",
                "ec2:RunInstances",
                "ec2:CreateTags",
                "ec2:ModifyImageAttribute"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:RebootInstances",
                "ec2:TerminateInstances"
            ],
            "Condition": {
                "StringEquals": {
                    "ec2:ResourceTag/role": "temporary_instance"
                }
            },
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
```
* GIT crypt with unlocked repository https://github.com/AGWA/git-crypt

# Build the application AMI
```
export ANSIBLE_HOST_KEY_CHECKING=False
```
```
ansible-playbook -i environments/hosting build-application.yml
```

# Build the bastion AMI
```
ansible-playbook -i environments/hosting build-bastion.yml
```

# Rollout Testing with Bamboo
```
ansible-playbook \
    -i environments/hosting-test \
    -e "aws_access_key=${bamboo.aws_access_key}" \ 
    -e "aws_secret_key=${bamboo.aws_secret_key}" \
    -e "monitoringEmailAddressParameter=${bamboo.monitoringEmailAddressParameter}" \ 
rollout-base.yml

ansible-playbook \
    -i environments/hosting-test \
    -e "aws_access_key=${bamboo.aws_access_key}" \
    -e "aws_secret_key=${bamboo.aws_secret_key}" \
    -e "hosting_application=jira" \
    -e "hosting_image=jira:hosting" \
    -e "hosting_ami=" \
    -e "hosting_priority=" \
    -e "hosting_bitbucket_port=7888" \
rollout-hosting.yml
```
Die Variable ```hosting_image``` kann folgende Werte annehmen:
* "jira:hosting"
* "confluence:hosting"
* "bitbucket:hosting"
* "bitbucket:hosting-testing"
* "confluence:hosting-testing"
* "jira:hosting-testing"
* "jira-ite:latest"
* "confluence-ite:latest"

Die Variable ```hosting_priority``` muss eine unique Number sein

Die Variable ```hosting_application``` kann folgende Werte annehmen:
* "jira"
* "confluence"
* "bitbucket"

# Delete Rollout Testing with Bamboo
```
ansible-playbook \
    -i environments/hosting-test \
    -e "aws_access_key=${bamboo.aws_access_key}" \
    -e "aws_secret_key=${bamboo.aws_secret_key}" \
delete-base.yml

ansible-playbook \
    -i environments/hosting-test \
    -e "aws_access_key=${bamboo.aws_access_key}" \
    -e "aws_secret_key=${bamboo.aws_secret_key}" \
    -e "hosting_application=" \
delete-hosting.yml
```

Die Variable ```hosting_application``` kann folgende Werte annehmen:
* "jira"
* "confluence"
* "bitbucket"
