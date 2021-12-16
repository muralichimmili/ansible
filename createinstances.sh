#!/bin/bash

UPDATE_DNS_RECORDS() {
    IP=$(aws ec2 describe-instances --filters  "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null )
    ## xargs is used to remove the double  quotes
    sed -e "s/DNSNAME/$1-dev.myhostedzone/" -e "s/IPADDRESS/${IP}/" record.json >/tmp/record.json
    aws route53 change-resource-record-sets --hosted-zone-id Z0576540AOW7M5U5BGNC --change-batch file:///tmp/record.json | jq  &>/dev/null
}

CREATE() {
  COUNT=$(aws ec2 describe-instances --filters  "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null  | wc -l)

  if [ $COUNT -eq 0 ]; then
    aws ec2 run-instances --launch-template LaunchTemplateId=lt-0e50cd8d4a17f3e80,Version=1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" "ResourceType=spot-instances-request,Tags=[{Key=Name,Value=$1}]" | jq &>/dev/null
  else
    echo -e "\e[1;33m$1 Instance already exists\e[0m"
    UPDATE_DNS_RECORDS $1
    return
  fi

  sleep 5

  UPDATE_DNS_RECORDS $1
}

if [ "$1" == "all" ]; then
  ALL=(frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment)
  for component in ${ALL[*]}; do
    echo "Creating Instance - $component "
    CREATE $component
  done
else
  CREATE $1
fi


