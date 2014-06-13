#!/usr/bin/env python

import os
import sys
import time
from novaclient.v1_1 import client

################################################################################
# Config:

#Networks:
# Private_1
# Provider_1
# External Network
# Internal_Network_1

USE_NETWORKS=['Provider_1']

FLOATING_IP_POOL='External Network'

# Define template for instance creation
# - can be modified by command-line parameters:
TEMPLATE={
    #'instance': 'testinstance', <- must be set via -add argument
    'image': 'cirros',
    'flavor': 'standard.xsmall',
}

################################################################################
# Functions:

def get_credentials():
    ''' Create a dictionary of credentials from environment variables '''

    credentials = {}
    credentials['username']   = os.environ['OS_USERNAME']
    credentials['api_key']    = os.environ['OS_PASSWORD']
    credentials['auth_url']   = os.environ['OS_AUTH_URL']
    credentials['project_id'] = os.environ['OS_TENANT_NAME']
    credentials['insecure']   = True

    return credentials

def associateFloatingIP(POOL_NAME, instance_id):
    ''' Associate a floating_ip address from specified pool
        with the specified instance '''

    availableIP=None
    #for fip in novaclient.floating_ips.list():
    #    if (fip.fixed_ip == None) and (fip.pool == POOL_NAME):
    #        availableIP=fip
    #        #availableIP=novaclient.floating_ips.get(fip)
    #        #print fip
    #        break
    
    if availableIP:
        print "Found available floating ip:" + str(availableIP)
    else:
        print "No available floating ip - creating IP"
        availableIP=novaclient.floating_ips.create(POOL_NAME)

    instance = novaclient.servers.get(instance_id)
    print "--> to instance " + str(instance)
    #print str(dir(instance))
     
    #import pdb; pdb.set_trace()
    availableIP=novaclient.floating_ips.create(POOL_NAME)

    OK=False
    while not OK:
        try:
            print "Try add_floating_ip: " + str(availableIP.ip)
            instance.add_floating_ip(availableIP.ip)
            OK=True
        except Exception as e:
            print("Failed to add floating_ip: " + str(e))
            time.sleep(5)
            pass

    #novaclient.servers.get(instance_id).add_floating_ip(availableIP)
    return availableIP

def getNetworkByName(name):
    ''' Get the network with the given name '''
    networks = novaclient.networks.list()

    for network in networks:
        #print network.label
        if network.label == USE_NETWORK:
            return network

    # If no exact match, try again with partial match:
    for network in networks:
        #print network.label
        if USE_NETWORK in network.label:
            return network

def getNetworksByNames(names):
    ''' Get the network(s) with the given name '''
    networks = novaclient.networks.list()
    selected = []

    for network in networks:
        #print network.label
        for name in names:
            if network.label == name:
                selected.append(network)

    return selected

def usage(text):
    ''' Show usage information and exit(1) '''
    if text:
        print; print(text);
    print
    print("Usage: " + sys.argv[0] + " [-add <name> | -del <name>]")
    sys.exit(1)

def fail(text):
    ''' Failure: Show error message and exit(1) '''
    print; print("fail: " + text);
    print
    sys.exit(1)

def listServers():
    ''' List servers on nova '''
    print( str( novaclient.servers.list() ) )

def serverRunning(name):
    ''' Return instance.id of instance with specified name '''

    instances = novaclient.servers.list()
    #print(str(instances))

    for i in instances:
        if i.name == name:
            return i.id

    # No matching instance found:
    return None

def startServer(imageHash, use_networks):
    ''' Create a new instance using the information in imageHash
        and 'use_networks' '''

    image = novaclient.images.find(name=imageHash['image'])
    flavor = novaclient.flavors.find(name=imageHash['flavor'])
    print("IMAGE=" + str(image))
    print("FLAVOR=" + str(flavor))

    nets = getNetworksByNames(use_networks)
    use_nics=[]
    for net in nets:
        use_nics.append({'net-id': net.id})

    print "use_nics=" + str(use_nics)
    #instance = novaclient.servers.create(name=imageHash['instance'], image=image, flavor=flavor, key_name="mykey", nics = use_nics)
    instance = novaclient.servers.create(name=imageHash['instance'], image=image, flavor=flavor, nics = use_nics)
    return instance
    
def waitWhileState(instance, state):
    ''' Loop while the specified instance is in the specified state '''
    status = instance.status

    # No log available for ESXi ??:
    #print novaclient.servers.get_console_output(instance.id,length=10)

    while status == state:
        time.sleep(5)
        instance = novaclient.servers.get(instance.id)
        status = instance.status
        print "Instance is in state '%s' ..." % status

    print "status: %s" % status

def waitUntilState(instance, state=None):
    ''' Loop until the specified instance is in the specified state
        or until instance no longer exists '''
    status = instance.status
    
    # No log available for ESXi ??:
    #print novaclient.servers.get_console_output(instance.id,length=10)

    while status != state:
        time.sleep(5)
        instance = novaclient.servers.get(instance.id)
        status = instance.status
        print "Instance is in state '%s' ..." % status

    print "status: %s" % status

def addNode(name):
    ''' Create a new VM instance with specified name '''
    id = serverRunning(name)
    if id:
        fail("Instance <" + name + "> is already running")

    TEMPLATE['instance']=name

    instance = startServer(TEMPLATE, USE_NETWORKS)
    print("Instance[" + name + "] is starting as '" + instance.id + "'")
    ip = associateFloatingIP(FLOATING_IP_POOL, instance.id)
    print("RESULT[" + ip.ip + "]")

    if wait:
        waitWhileState(instance, 'BUILD')


def delNode(name):
    ''' Create the VM instance with specified name '''

    id = serverRunning(name)
    if not id:
        fail("Instance <" + name + "> is not running")

    novaclient.servers.delete(id)
    if wait:
        try:
            instance = novaclient.servers.get(id)
            waitUntilState(instance) # exists
        except Exception as e:
            #print "Instance deleted: " + str(e)
            print "Instance deleted [" + instance.name + ", " + instance.id+"]"

########################################
# Main function:

def main():
    ''' Main function called when module invoked as command-line script
        - processes command-line args
        - adds/deletes named instance
    '''

    global novaclient, wait

    if len(sys.argv) == 1:
        usage("Missing arguments")

    add_node=None
    del_node=None
    wait = False

    a=0;
    while a<len(sys.argv)-1:
        a+=1
        #print("LOOP var[" + str(a) + "]=" + sys.argv[a])

        # Main options: -------------------------------
        if sys.argv[a] == "-add":
            a += 1
            add_node=sys.argv[a]
            #print("add_node="+add_node)
            continue

        if sys.argv[a] == "-del":
            a += 1
            del_node=sys.argv[a]
            #print("del_node="+del_node)
            continue

        if sys.argv[a] == "-wait":
            wait = True
            continue

        # Image/flavor options ------------------------
        if sys.argv[a] == "-image":
            a += 1
            TEMPLATE['image']=sys.argv[a]
            continue
    
        if sys.argv[a] == "-flavor":
            a += 1
            TEMPLATE['flavor']=sys.argv[a]
            continue

        # Test cases: ---------------------------------
        if sys.argv[a] == "-testfp":
            a += 1
            instance_id=sys.argv[a]
            novaclient = client.Client(**get_credentials())
            ip = associateFloatingIP(FLOATING_IP_POOL, instance_id)
            print("RESULT[" + ip.ip + "]")
            sys.exit(0)

        usage("Unknown argument:" + sys.argv[a])

    if add_node and del_node:
        usage("Can only select -add or -del")

    if not(add_node or del_node):
        usage("Must select -add or -del")


    ########################################
    # Main:

    # Create new nova client object:
    novaclient = client.Client(**get_credentials())

    # Add-node: i.e. start a new instance
    if add_node:
        addNode(add_node)
        sys.exit(0)

    # Del-node: i.e. delete an instance
    if del_node:
        delNode(del_node)
        sys.exit(0)

    sys.exit(0)

    
################################################################################
# Args:

if __name__ == "__main__":
    s="HELLO WORLD"
    main()


#if not novaclient.keypairs.findall(name="mykey"):
#    with open(os.path.expanduser('~/.ssh/id_rsa.pub')) as fpubkey:
#        novaclient.keypairs.create(name="mykey", public_key=fpubkey.read())
#networks = novaclient.networks.list()
#print("NETWORKS=" + str(networks))
##ns = novaclient.server.networks()
##print("NETWORKS=" + str(ns))

#use_nics=[{'net-id': u'7ab4ea47-14a4-45aa-acb8-2f3b7b4973da'}]
#import pdb; pdb.set_trace()




