#!/usr/bin/env python


import novaclient
import novaclient.auth_plugin
from novaclient import client
from novaclient import exceptions as exc
import novaclient.extension
from novaclient.openstack.common import strutils
from novaclient import utils
from novaclient.v1_1 import shell as shell_v1_1
from novaclient.v3 import shell as shell_v3

import time
import os
import sys

#self.cs = client.Client(options.os_compute_api_version,
#    os_username,
#    os_password,
#    os_tenant_name,
#        tenant_id=os_tenant_id,
#        auth_url=os_auth_url, insecure=insecure,
#        region_name=os_region_name, endpoint_type=endpoint_type,
#        extensions=self.extensions, service_type=service_type,
#        service_name=service_name, auth_system=os_auth_system,
#        auth_plugin=auth_plugin,
#        volume_service_name=volume_service_name,
#        timings=args.timings, bypass_url=bypass_url,
#        os_cache=os_cache, http_log_debug=options.debug,
#        cacert=cacert, timeout=timeout)

user = os.getenv('OS_USERNAME')
pword = os.getenv('OS_PASSWORD')
tenant = os.getenv('OS_TENANT_NAME')
os_auth_url = os.getenv('OS_AUTH_URL')

api='2'
api='1.1'

print "Connecting using " + "USER="+user + ", PWORD="+pword + ", URL="+os_auth_url

nova = client.Client(api,
           user, pword, tenant, os_auth_url
           #auth_url=os_auth_url
           #utils.env('OS_USERNAME'),
           #utils.env('OS_PASSWORD'),
           #None, os_auth_url
           #utils.env('OS_AUTH_URL'),
        )

print
print "Connected"
print "FLAVORS=" + str(nova.flavors.list())
print "SERVERS=" + str(nova.servers.list())
print "IMAGES=" + str(nova.images.list())
print "KEYPAIRS=" + str(nova.keypairs.list())

max_count=1
instances_to_create=1
if len(sys.argv) > 1:
    instances_to_create=int(sys.argv[1])
if len(sys.argv) > 2:
    max_count=int(sys.argv[2])

instances=len(nova.servers.list())

print "INSTANCES=" + str(instances) + " MAX_COUNT=" + str(max_count)
#sys.exit(0)

#image1=nova.images[0]
#image1=nova.images.get(0)
#image1=nova.images.get("/images/0")

#image = nova.images.find(name="cirros")
#image = nova.images.get(image1.id)
image = nova.images.find(name="cirros-0.3.1-x86_64-uec")
#flavor = nova.flavors.find(name="m1.tiny")
flavor = nova.flavors.find(name="m1.nano")

def createInstance(iname, max_count=1):
    if max_count == 1:
        print "Creating instance '" + iname + "'"
    else:
        print "Creating " + str(max_count) + " instances '" + iname + "'"

    #sys.exit(0)
    instance = nova.servers.create(name=iname, image=image, flavor=flavor, max_count=max_count)
    print "SERVERS=" + str(nova.servers.list())

    status = instance.status
    while status == 'BUILD':
        time.sleep(5)
        # Retrieve instance again so status field updates:
        instance = nova.servers.get(instance.id)
        status = instance.status

    print "status: " + str(status)

for i in range(instances_to_create):
    iname="test"+str(1+i+instances)
    createInstance(iname, max_count)




