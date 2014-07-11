
HP Helion OpenStack - related tools
===================================

These are largely untested tools to facilitate installation of HP Helion OpenStack.

Currently being tested with the June 2014 Community Edition release for Baremetal installations.

baremetal.csv
--------------

As described in the HP Helion installation instructions.

This is just a template, you'll need to put your
   - MAC address of your PXE bootable interface of each Baremetal node
   - ilo user/passwords
   - IP adress of your ilo interface
   - cpu,RAM,disk

auto_helion.sh
--------------

This script is a wrapper to automate the installation.

It assumes you have installed Ubuntu on your seed host (physical machine).
It will install the necessary packages and restart libvirt-bin.

It has been tested on Ubuntu 14.04 only.
auto_helion.sh will login to the seedhost and perform actions from there.

Note you will need to add an entry in your local ~/.ssh/config file to refer to your seedhost:
    Host seedhost
        HostName BAREMETAL_SEED_IP
        User user

The auto_helion.sh will use the ipmitools.sh script combined with your baremetal.csv file
to auto power up/power down your baremetal nodes.

It can be used as:
    # Checks connectivity and sets up auto-login to your seedhost:
    ./auto_helion.sh -0

    # Copies files to the seedhost: (your baremetal.csv and the 4.5GBy Helion distribution)
    ./auto_helion.sh -1

    # Installs required Ubuntu packages
    ./auto_helion.sh -2

    # STEP3: Will create, or re-create, the Seed VM:
    ./auto_helion.sh -3

    # STEP4: Will perform the installation:
    # To be described:
    ./auto_helion.sh -4




ipmitool.sh
--------------

Using ipmitools.sh you can interrogate the power status of your baremetal nodes.
You'll of course require local installation of the ipmitools package.

This script will read the entries in your baremetal.csv

To check the power status of your nodes:
    ./ipmitools.sh 

To check power down all your nodes:
    ./ipmitools.sh -off

To check power up all your nodes:
    ./ipmitools.sh -on

To check perform any other action:
    ./ipmitools.sh -a  <action>

e.g. to set all nodes to PXE boot mode:
    ./ipmitools.sh -a chassis bootdev pxe



