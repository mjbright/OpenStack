#!/bin/bash

DEVSTACK_DIR=/home/mjb/src/git/devstack
cd $DEVSTACK_DIR

echo
echo "# Running 'sudo unstack.sh':"
sudo ./unstack.sh >/dev/null 2>&1

echo
echo "# Killing running stack processes:"
ps -fade | grep stack | grep -v grep | grep -v $$
PIDS=`ps -fade | grep stack | grep -v grep | awk '{print $2;}' | grep -v $$`
if [ ! -z "$PIDS" ];then
    echo "Killing running processes [$PIDS]"
    sudo kill -9 $PIDS
    ps -fade | grep stack | grep -v grep
fi

echo
echo "# Removing any screen locks:"
sudo ls -al /var/run/screen/S-stack/
SCREENS=`sudo ls -1 /var/run/screen/S-stack/`

for SCREEN in $SCREENS;do
    echo "Removing screen $SCREEN:"
    sudo rm -rf /var/run/screen/S-stack/$SCREEN
done

