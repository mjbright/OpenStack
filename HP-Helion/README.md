
HP Helion OpenStack - related tools
===================================

These are largely untested tools to facilitate installation of HP Helion OpenStack.

Currently being tested with the October 2014 "HP Helion OpenStack" GA release v1.0
for Baremetal installations.

baremetal.csv
--------------

As described in the HP Helion installation instructions.

This is just a template, you'll need to put your
   - MAC address of your PXE bootable interface of each Baremetal node
   - ilo user/passwords
   - IP adress of your ilo interface
   - cpu,RAM,disk

INSTALLER.sh
--------------

This script is a wrapper to automate the installation.
It is to be run from your seedhost as root user
(the script should be configured with the seedhost and VM ip address
 and will detect if not run from root@seedhost)

It has been tested on Ubuntu 14.04 only.

The auto_helion.sh will use the ipmitools.sh script combined with your baremetal.csv file
to auto power up/power down your baremetal nodes.

TO BE DONE: Document this new script

    # Reinitializes networking/destroys the SEED VM/Creates the SEED VM:
    ./INSTALLER.sh -1

    # Runs the installer
    ./INSTALLER.sh -2

TOOLS.sh
----------

This script is a wrapper to facilitate connections to the different nodes.
It is to be run from your seedhost as root user
(the script should be configured with the seedhost and VM ip address
 and will detect if not run from root@seedhost)

TO BE DONE: Document this new script

    # Show the credentials to connect to Undercloud Horizon dashboard as admin:
    ./TOOLS.sh -uc

    # Connect to the Undercloud node as heat-admin user:
    ./TOOLS.sh -ucssh
    ./TOOLS.sh -ucssh uptime

    # List the Overcloud nodes
    # Show the credentials to connect to Overcloud Horizon dashboard as admin:
    ./TOOLS.sh -oc

    # Connect to the 1st Overcloud node (in above list) as heat-admin user:
    ./TOOLS.sh -ocssh 1
    ./TOOLS.sh -ocssh 1 uptime

    # Connect to the each Overcloud node and perform specified command (e.g. uptime)
    ./TOOLS.sh -ocssh uptime


ipmitool.sh
--------------

Using ipmitools.sh you can interrogate the power status of your baremetal nodes.
You'll of course require local installation of the ipmitools package.

This script will read the entries in your baremetal.csv

To check the power status of your nodes:
    ./ipmitools.sh 
    ./ipmitools.sh +v # quiet mode: Don't echo commands

To power down all your nodes:
    ./ipmitools.sh -off

To power up all your nodes:
    ./ipmitools.sh -on

To perform any other action:
    ./ipmitools.sh -a  <action>

e.g. to set all nodes to PXE boot mode:
    ./ipmitools.sh -a chassis bootdev pxe



