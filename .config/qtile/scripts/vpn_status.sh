#! /bin/bash

vpn_status=$(expressvpn status | head -1)
location=$(cut -d " " -f 3- <<< $vpn_status)
isconnected=$(cut -d " " -f 1 <<< $vpn_status)


if [ $isconnected = "Not" ]
then
    printf %s "Not connected"
else
    printf %s "$location"
fi

