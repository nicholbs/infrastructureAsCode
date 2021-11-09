#!/bin/bash -v

#sjekk om fil med scale up/down URL eksisterer
FILE=~/infrastructureAsCode/manager/scale_up_url
if [ -f "$FILE" ]; then
    echo "$FILE exists."
else
    echo "$FILE does NOT exist"
    exit 1
fi

#Hent scale up/down URL
scale_up_url=$(cat ~/infrastructureAsCode/manager/scale_up_url)

#Send POST forespørsel om å øke antall servere til openstack API-et 
curl -X POST $scale_up_url


