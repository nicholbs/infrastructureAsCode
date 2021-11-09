#!/bin/bash -v

#Check if file to hold the Openstack API scale down url exists 
FILE=~/infrastructureAsCode/manager/scale_down_url
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else
    echo "$FILE does NOT exist"
    exit 1
fi

#Retrieve the URL
scale_up_url=$(cat ~/infrastructureAsCode/manager/scale_down_url)

#Send POST request to Openstack API which deletes one of the gitlab servers and removes it from load_balancer
curl -X POST $scale_up_url

