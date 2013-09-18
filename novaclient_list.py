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

import os

# Get authentication variables from environment (source devstack/openrc):
user = os.getenv('OS_USERNAME')
if user == None:
    die("OS_USERNAME not set - source your openrc")

pword = os.getenv('OS_PASSWORD')
if pword == None:
    die("OS_PASSWORD not set")

tenant = os.getenv('OS_TENANT_NAME')
if tenant == None:
    die("OS_TENANT_NAME not set")

os_auth_url = os.getenv('OS_AUTH_URL')
if os_auth_url == None:
    die("OS_AUTH_URL not set")

api='1.1'

print "Connecting using " + "USER="+user + ", PWORD="+pword + ", URL="+os_auth_url

nt = client.Client(api, user, pword, tenant, os_auth_url)

print
print "Connected"
print "FLAVORS=" + str(nt.flavors.list())
print "INSTANCES(servers)=" + str(nt.servers.list())
print "IMAGES=" + str(nt.images.list())
print "KEYPAIRS=" + str(nt.keypairs.list())


