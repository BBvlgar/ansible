# AWS Logs

Installs the AWS Logs Agent and configures it to send logs to cloudwatch.

## Requirements

* AWS Account with Cloudwatch Logs access.

## Role Variables

### awslogs_application

```
awslogs_application:
  - apache_access
```

A list of application logs you want to stream. Each entry corresponds to a template file in `templates`.

### awslogs_key

```
awslogs_key: notSoSecretKey
```
Sets the AWS Access Key ID for the IAM user used to access Cloudwatch.

### awslogs_secret_key

```
awslogs_secret_key: verySecretKey
```
Sets the AWS Secret Access Key for the IAM user used to access Cloudwatch.

### awslogs_region

```
awslogs_region: eu-central-1
```
Sets the region to stream logs to.

### awslogs_enabled

```
awslogs_enabled: true
```
Enable (true) or disable (false) the autostart via upstart. However, this works only partially since the awslogs-nanny (Cron job) will start the service anyhow.

## Dependencies

None

## Example Playbook

```
    - hosts: loggers
      roles:
         - { role: awslogs, awslogs_key: 42, awslogs_secret_key: 13 }
```
