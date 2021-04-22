#!/bin/bash

function log() {
  echo "launch-config: " $@ | logger -s
}

function trim() {
    echo "$1" | sed -e 's/\[//;s/\]//' | tr -d '\040\011\012\015"'
}

#
# Get the volume state of @volumeId
#
# function getVolumeState() {
#     local volumeId=$1
#     local state=$($AWS ec2 describe-volumes --region $region --volume-ids "$volumeId" --query 'Volumes[*].[State]')
#     local state=$(trim "$state")
#     echo $state
# }

#
# Get the instance id volume @volumeId is currently attached to
#
# function getVolumeAttachment() {
#     local volumeId=$1
#     local attachment=$($AWS ec2 describe-volumes --region $region --volume-ids "$volumeId" --query 'Volumes[*].Attachments[*].[InstanceId]')
#     local attachment=$(trim "$attachment")
#     echo $attachment
# }

#
# Get the instance id of the current instance via meta-data
#
function getInstanceId() {
    local id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    echo "$id"
}

#
# Get the iam role name of the current instance via meta-data
#
function getIAMRoleName() {
    local name=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
    echo "$name"
}

#
# Attach an available volume with the @volumeId to the instance @instanceId
#
# function attachVolume() {
#     local volumeId="$1"
#     local instanceId="$2"
#     local device="$3"
#     $AWS ec2 attach-volume --region $region --volume-id "$volumeId" --instance-id "$instanceId" --device "$device"
#     local status=$?
#     if [ $status -eq 0 ] ; then
#       log "INFO: Successfully attached volume $volumeId to instance $instanceId"
#     else
#       log "ERROR: Failed to attach volume $volumeId to instance $instanceId"
#       exit 1
#     fi
# }

#
# Get the status of the current cloudformation stack and return it
#
function getStackStatus() {
  local stack=$1
  local status=$($AWS cloudformation describe-stacks --stack-name "$stack" --region $region --query 'Stacks[*].[StackStatus]')
  local status=$(trim "$status")
  echo $status
}

#
# Get the status of the current cloudformation stack and return it
#
function getDatabasePassword() {
  local stackName=$1
  local dbPassword=$($AWS secretsmanager get-secret-value --secret-id "$stackName" --region $region | jq --raw-output ".SecretString")
  local dbPassword=$(trim "$dbPassword")
  echo $dbPassword
}


#
# @sysLogs
# @awsLogsDir
# Update awslogs agent with the current log_group and log_stream
#
function updateAwsLogs() {

  local sysLogs=$1
  local application=$2
  local applicationLogs=$3

  # Update log_group_name
  sed -i -E "s/syslog_group/$sysLogs/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  sed -i -E "s/application_group/$applicationLogs/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

  # Update log_stream_name
  sed -i -E "s/syslog_stream/$(hostname -f)/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  sed -i -E "s/application_stream/$(hostname -f)/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

  # Update application file path
  if [ "$datacenterMode" == true ]; then
      sed -i -E "s/application_file_path/\/mnt\/data\/log\/atlassian-$application.log/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  else
     sed -i -E "s/application_file_path/\/mnt\/shared\/log\/atlassian-$application.log/" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  fi



  

  service amazon-cloudwatch-agent restart

}

#
# @application
# @databaseEndpoint
# @databaseName
# @databaseArguments
# @dataDir
# Update the database endpoint for @application
#
function confluenceSetClusterConfig() {
  export atl_db_host=$1
  export atl_jdbc_db_name=$2
  export atl_jdbc_query_params=$3
  export atl_jdbc_user=$4
  export atl_jdbc_password="$(getDatabasePassword $7)"

  export atl_hazelcast_network_aws_iam_role="$(getIAMRoleName)"
  export atl_hazelcast_network_aws_tag_key=$5
  export atl_hazelcast_network_aws_tag_value=$6
  export atl_aws_stack_name=$7

  local dataDir=$8

  if [ -f $dataDir/confluence.cfg.xml ]; then
    log "INFO: Config file exist already"
    return 0
  fi

  j2 /home/ubuntu/confluence.cfg.xml.j2 > $dataDir/confluence.cfg.xml

  return 0
}

function jiraSetClusterConfig() {

  export atl_db_host=$1
  export atl_jdbc_db_name=$2
  export atl_jdbc_query_params=$3
  export atl_jdbc_user=$4
  export atl_jdbc_password="$(getDatabasePassword $7)"

  local dataDir=$5
  local sharedDir=$6
  local nodeID="$(getInstanceId)"

  if [ -f $sharedDir/jira-config.properties ]; then
    cp $sharedDir/jira-config.properties $dataDir/jira-config.properties
  fi

  if [ -f $dataDir/dbconfig.xml ] && [ -f $dataDir/cluster.properties ]; then
    log "INFO: Config files exist already"
    return 0
  fi

  j2 /home/ubuntu/jira_dbconfig.xml.j2 > $dataDir/dbconfig.xml

  echo "jira.node.id = "$nodeID > $dataDir/cluster.properties
  echo "jira.shared.home = /shared" >> $dataDir/cluster.properties

  return 0
}

function bitbucketSetClusterConfig() {
  local databaseEndpoint = $1
  local databaseName = $2
  local databaseArguments= $3
  local databaseUsername = $4
  local clusterTagKey = $5
  local clusterTagValue = $6
  local stackName = $7
  local dataDir = $8

  if [ -f $dataDir/shared/bitbucket.properties ]; then
    if grep -q "hazelcast.network.aws" "$dataDir/shared/bitbucket.properties"; then
      log "INFO: Cluster config exist already"
    else
      echo "hazelcast.network.aws=true" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.network.multicast=false" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.network.aws.iam.role=$(getIAMRoleName)" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.network.aws.region=eu-central-1" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.network.aws.tag.key=$clusterTagKey" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.network.aws.tag.value=$clusterTagValue" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.group.name=$stackName" >> $dataDir/shared/bitbucket.properties
      echo "hazelcast.group.password=$stackName" >> $dataDir/shared/bitbucket.properties
    fi

    # Set Database credentials
    sed -i "s|jdbc.url=.*$|jdbc.url=jdbc:postgresql://$1/$databaseName?$databaseArguments|" $dataDir/shared/bitbucket.properties
    sed -i "s|jdbc.user=.*$|jdbc.user=$databaseUsername|" $dataDir/shared/bitbucket.properties
    sed -i "s|jdbc.password=.*$|jdbc.password=$(getDatabasePassword $stackName)|" $dataDir/shared/bitbucket.properties
    
    return 0
  
  fi
  
  return 0
}

#
# @application
# @databaseEndpoint
# @databaseName
# @databaseArguments
# @dataDir
# Update the database endpoint for @application
#
function updateDatabaseEndpoint() {

  local application=$1
  local databaseEndpoint=$2
  local databaseName=$3
  local databaseArguments=$4
  local dataDir=$5
  local config=""
  local path=""

  case $application in
    jira)
      config=dbconfig.xml
      path='//jira-database-config//jdbc-datasource//url'
    ;;
    confluence)
      config=confluence.cfg.xml
      path='//confluence-configuration//properties//property[@name="hibernate.connection.url"]'
    ;;
    bitbucket)
      config=shared/bitbucket.properties
    ;;
    *)
      log "ERROR: Can not update Config file with new $databaseEndpoint. $application is currently not supported."
    ;;
  esac

  if [ -e $dataDir/$config ] ; then
    if [ "$application" == "bitbucket" ]; then
          #bitbucket configuration
          sed -i 's/jdbc.driver.*$/jdbc.driver=org.postgresql.Driver/' $dataDir/$config
      	  sed -i "s|jdbc.url=.*$|jdbc.url=jdbc:postgresql://$databaseEndpoint/$databaseName?$databaseArguments|" $dataDir/$config
        else
          #confluence and jira configuration
          log "INFO: Updating $config with $databaseEndpoint"
          xmlstarlet ed -P -S -L --update "$path" --value "jdbc:postgresql://$databaseEndpoint/$databaseName?$databaseArguments" $dataDir/$config
        fi
  else
    log "INFO: Could not update $config since $dataDir/$config does not (yet) exist"
  fi

  return 0
}

#
# Format @device with @fileystem
#
# function formatDevice() {
#   local device=$1
#   local filesystem=$2
#   local status=$(file -s $device)

#   if ! stat $device > /dev/null ; then
#     log "ERROR: Device $device could not be found"
#     return 1
#   fi

#   if echo $status | grep "^${device}: data$" >/dev/null ; then
#     log "INFO: Device $device contains no filesystem. It will be formated with $filesystem"
#     mount $device $(mktemp) > /dev/null || mkfs -t $filesystem $device
#   else
#     log "INFO: Device $device already formated."
#   fi

#   log "INFO: Status $status"
#   return 0
# }

function setSophosThreads() {
    availableCores=$(grep -c ^processor /proc/cpuinfo)
    /opt/sophos-av/bin/savconfig set ThreadsPerProcess $availableCores
    /opt/sophos-av/bin/savconfig set MaximumThreads $availableCores
    log "INFO: Set Sophos used threads to $availableCores"
    /etc/init.d/sav-protect restart
}