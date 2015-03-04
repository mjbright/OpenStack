#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals # all string literals will be Unicode by default.

'''
TODO: Create a pexpect_client class which holds it's own metadata on login etc.
TODO: Rearchive on github
TODO: IMPROVE - Allow to perform command(s), e.g. df on each node
TODO: IMPROVE - Select all/subset of nodes - for key installation, for running command, ...
TODO: Make command-line options usable/easy to understand/remember
TODO: Parse nova list of (undercloud nova list) overcloud nodes:
TODOL     -> optionally append to Default.ini
TODO:     -> Auto create an ssh-config file for auto-logins to nodes
TODO: Extend to scp capabilities to all nodes (better just via ssh key ... but may be needed)
TODO: Get addresses from ini file or from nova list
TODO: Choose ini file, section
TODO: Login via pexpext or via keys or via password
TODO: Install ssh keys (same key for all nodes, or by type, or by node... - just same key for now)
TODO: Check ssh keys installation
TODO: Reminder - use of ^] to quit
'''

import re
import pexpect
import sys
import time

import argparse
import ConfigParser, os

VERBOSE=0

platform_config_file='Default.ini'

#def enum(*sequential, **named):
    #enums = dict(zip(sequential, range(len(sequential))), **named)
    #return type('Enum', (), enums)
#>>> Numbers = enum('ZERO', 'ONE', 'TWO')

NODE_SEEDHOST=1
NODE_SEEDHOST_ROOT=2
NODE_SEEDVM=3
NODE_UNDERCLOUD=4
NODE_UNDERCLOUD_ROOT=5

# 10+: controller nodes
#NODE_SWIFT0=10
#NODE_SWIFT1=11
#NODE_CONTROLLER0=12
#NODE_CONTROLLER1=13
#NODE_CONTROLLER0MGMT=14

NODE_TO_ENUMERATE=99
# NODES are then indices into nodes table + 20

# 20+: compute nodes

PLATFORM="DEFAULT"

TEST_STRING="""
root@undercloud-undercloud-a52axnkcnktt:~# nova list
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
| ID                                   | Name                                                 | Status | Task State | Power State | Networks             |
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
| 1834f12d-f6bd-4cb0-b1b0-6581faa3568c | overcloud-ce-controller-SwiftStorage0-fe4f4nn24siz   | ACTIVE | -          | Running     | ctlplane=10.3.160.26 |
| cbee9583-9f00-4496-9ee5-37a9c681be4f | overcloud-ce-controller-SwiftStorage1-mmc3suyyahll   | ACTIVE | -          | Running     | ctlplane=10.3.160.23 |
| 35a8c6bc-ff97-49ce-b6c5-35ecb7f83c01 | overcloud-ce-controller-controller0-s6xwsyfmverl     | ACTIVE | -          | Running     | ctlplane=10.3.160.21 |
| 5a45abe8-cc0d-4d2f-a972-b2f46517fb32 | overcloud-ce-controller-controller1-us7csix3shzn     | ACTIVE | -          | Running     | ctlplane=10.3.160.24 |
| 3a3bbc73-4cb0-46a2-bbcd-2964a2c85eee | overcloud-ce-controller-controllerMgmt0-we62572getmg | ACTIVE | -          | Running     | ctlplane=10.3.160.27 |
| 86d0cfd3-f113-47cb-b950-3a44f5a2176a | overcloud-ce-novacompute1-NovaCompute1-vblrfdhvbele  | ACTIVE | -          | Running     | ctlplane=10.3.160.28 |
| ba088383-30b1-452e-aa41-5a391d46266b | overcloud-ce-novacompute2-NovaCompute2-g22zqyaop7tz  | ACTIVE | -          | Running     | ctlplane=10.3.160.29 |
| 734fde15-637e-4f53-b9f3-bb914e8c36f6 | overcloud-ce-novacompute3-NovaCompute3-j3vxazpncuh7  | ACTIVE | -          | Running     | ctlplane=10.3.160.30 |
| da10e6d5-94dc-4778-998b-37b40b483237 | overcloud-ce-novacompute4-NovaCompute4-xpr57l2aifqa  | ACTIVE | -          | Running     | ctlplane=10.3.160.38 |
| fce487e3-d8b7-4ae5-9a32-24e218b2e8ae | overcloud-ce-novacompute5-NovaCompute5-w2tlc7cdpgkq  | ACTIVE | -          | Running     | ctlplane=10.3.160.39 |
| 7a5a12b9-34ca-4269-8a91-4078653cc931 | overcloud-ce-novacompute6-NovaCompute6-whskj2huch2l  | ACTIVE | -          | Running     | ctlplane=10.3.160.40 |
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
trailing junk
"""

TEST_SHORT_STRING="""
root@undercloud-undercloud-a52axnkcnktt:~# nova list
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
| ID                                   | Name                                                 | Status | Task State | Power State | Networks             |
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
| 7a5a12b9-34ca-4269-8a91-4078653cc931 | overcloud-ce-novacompute6-NovaCompute6-whskj2huch2l  | ACTIVE | -          | Running     | ctlplane=10.3.160.40 |
+--------------------------------------+------------------------------------------------------+--------+------------+-------------+----------------------+
trailing junk
"""

def TOBE_DONE_QUIETEN(level, FUNCTION, *ARGS):
    """ Apply temporary debug level to quieten, or louden some function call """
    global VERBOSE

    save_VERBOSE = VERBOSE
    VERBOSE = level

    if ARGS == None:
        FUNCTION()
    else:
        FUNCTION(ARGS)

    VERBOSE = save_VERBOSE

def DEBUG(level, message):
    """ Print the message if VERBOSE is greater or equal to the specified debug level """
    if VERBOSE >= level:
        print(message)

# TODO: Allow multiple subactions
COMMAND_SHOW_UNDERCLOUD_PASSWORDS=101
COMMAND_SHOW_OVERCLOUD_PASSWORDS=102
COMMAND_UC_NOVALIST=103
COMMAND_OC_NOVALIST=104
COMMAND_UC_NOVALIST_ALLTENANTS=105
COMMAND_OC_NOVALIST_ALLTENANTS=106
COMMAND_ONALL_NODES=107
COMMAND_INTERACT=199 # default subaction

################################################################################
# Functions:

def STEP(STEP):
    """ Print a formatted DEBUG message to show the current performed STEP """
    DEBUG(1,"-------- STEP[" + STEP + "] --------")

def parseArgs():
    """ Parse the command-line arguments using the parseargs module """
    parser = argparse.ArgumentParser(description='Process optional platform and node names')
    #parser.add_argument('v', metavar='verbose', type=int, default=0, help='set verbose level')
    parser.add_argument('--verbose', '-v', dest='VERBOSE', action='count')
    parser.add_argument('--keys',    '-k', dest='USE_KEYS', action='store_const', const=1)

    parser.add_argument('--platform', '-P',  dest='PLATFORM', action='store') # Specify platform

    parser.add_argument('--seed',      '-S', dest='NODES', action='append_const', const=NODE_SEEDHOST) #, action='store')
    parser.add_argument('--seed-root', '-R', dest='NODES', action='append_const', const=NODE_SEEDHOST_ROOT) #, action='store')
    parser.add_argument('--seed-vm',   '-V', dest='NODES', action='append_const', const=NODE_SEEDVM) #, action='store')
    parser.add_argument('--undercloud','-U', dest='NODES', action='append_const', const=NODE_UNDERCLOUD) #, action='store')
    parser.add_argument('--undercloud-root','-W', dest='NODES', action='append_const', const=NODE_UNDERCLOUD_ROOT) #, action='store')

    parser.add_argument('--upwd', dest='COMMANDS', action='append_const', const=COMMAND_SHOW_UNDERCLOUD_PASSWORDS)
    parser.add_argument('--opwd', dest='COMMANDS', action='append_const', const=COMMAND_SHOW_OVERCLOUD_PASSWORDS)
    parser.add_argument('--unl', dest='COMMANDS', action='append_const', const=COMMAND_UC_NOVALIST)
    parser.add_argument('--onl', dest='COMMANDS', action='append_const', const=COMMAND_OC_NOVALIST)
    parser.add_argument('--unla', dest='COMMANDS', action='append_const', const=COMMAND_UC_NOVALIST_ALLTENANTS)
    parser.add_argument('--onla', dest='COMMANDS', action='append_const', const=COMMAND_OC_NOVALIST_ALLTENANTS)
    parser.add_argument('--cmd', dest='COMMAND_ONALL_NODES_ARGS', action='store')

    parser.add_argument('--inc', dest='INC_NODES', action='append')
    parser.add_argument('--exc', dest='EXC_NODES', action='append')

    args = parser.parse_args()
    #if args: print(args.accumulate(args.integers))
    return args

def die(msg):
    """ Fail and exit """
    print(msg)
    sys.exit(1)

def readConfig(section):
    """ Read the specified section from the Default.ini platfornm_config file """
    #[Platform]
    #seed_host=user@10.3.160.10
    #seed_vm=10.3.160.6
    #undercloud=10.3.160.11
    CFG=dict()

    config = ConfigParser.ConfigParser()
    config.read(platform_config_file)

    CFG['seed_host']= config.get(section, 'seed_host')
    CFG['seed_user']= config.get(section, 'seed_user')
    CFG['seed_password']= config.get(section, 'seed_password')

    CFG['seed_vm']= config.get(section, 'seed_vm')
    CFG['undercloud']= config.get(section, 'undercloud')

    CFG['seed_login']= CFG['seed_user'] + '@' + CFG['seed_host']

    return CFG

def showClient(label, client):
    print(label, str(client).split('\n')[0])

def waitOnPossibleSudoPasswordPrompt(client, password):
    """ Check if password prompt from sudo, if so send password and wait for shell prompt """
    DEBUG(2,"Waiting for possible password prompt")
    i = client.expect (['password for', '[#\$] '])
    if i == 0:
        DEBUG(2,"Sending password <" + str(client.match.string) +">")
        client.sendline(password)
        #STEP("sent password/waiting on prompt")
        client.expect('root.*')
        #STEP("GOT prompt")
        #print("PROMPT <" + client.match.string + ">")
    elif i==1:
        #print("OK <" + str(client.match.string) + ">")
        pass
    #waitOnVMRootPrompt()

#client.expect('password:')
#client.sendline (my_secret_password)
## We expect any of these three patterns...
#i = client.expect (['Permission denied', 'Terminal type', '[#\$] '])
#if i==0:
#    print 'Permission denied on host. Can't login'
#    client.kill(0)
#elif i==2:
#    print 'Login OK... need to send terminal type.'
#    client.sendline('vt100')
#    client.expect ('[#\$] ')
#elif i==3:
#    print 'Login OK.'
#    print 'Shell command prompt', client.after
#

def connectToSeed():
    """ Create a Pexpect connecton to the seedhost """
    # Use spawnu for Python3 compatibility

    ssh_passwd_opts=''
    if CONFIG['seed_password'] == '':
        command = '/usr/bin/ssh ' + ssh_passwd_opts + ' ' + CONFIG['seed_login']
        if VERBOSE:
            print("Logging in using ssh-keys <" + command + ">")
        client = pexpect.spawnu(command)
        seen = client.expect('^.+')
        if seen == 0:
            if VERBOSE:
                print(client.before)
            #die("SSH-KEYS: failed to log in to seedhost <" + CONFIG['seed_login'] + "> using ssh-keys")
        STEP("SEEDHOST")
        return client

    #ssh_passwd_opts='-o PreferredAuthentications=keyboard-interactive -o PubkeyAuthentication=no'
    ssh_passwd_opts='-o PubkeyAuthentication=no'
    if VERBOSE:
        print("Logging in using user entered password")
    command = '/usr/bin/ssh ' + ssh_passwd_opts + ' ' + CONFIG['seed_login']
    if VERBOSE:
        print("Logging in using password <" + command + ">")
    client = pexpect.spawnu(command)
    # user@10.3.160.10's password:
    #seen = client.expect('.+s password:')
    try:
        seen = client.expect('password:', timeout=10)
        #i = client.expect ([pattern1, pattern2, pattern3, etc])
    except Exception as e:
        if VERBOSE:
            print("Expected password prompt - timed out on command (" + command + ")")
            print("Exception was thrown, debug information:")
            print(str(e))
        else:
            print("Expected password prompt - timed out on command (" + command + ")")

        # ?? print(str(client))
        # It is also useful to log the client's input and out to a file or the screen.
        # The following will turn on logging and send output to stdout (the screen).
        #client = pexpect.spawn (foo)
        #client.logfile = sys.stdout
        sys.exit(1)

    #if VERBOSE: print("SEEN=" + str(seen))
    if seen == 0:
        if VERBOSE: print(client.before)
        #die("PASSWORD: failed to log in to seedhost <" + CONFIG['seed_login'] + "> using password")

    if VERBOSE: print("Sending password (contains " + str(len(CONFIG['seed_password'])) + " chars)")
    client.sendline(CONFIG['seed_password'])
    #die("PASSWORD")

    STEP("SEEDHOST")
    return client

def waitOnVMRootPrompt():
    """ Wait for the root@hLinux prompt of the seed VM """
    print("waiting on VMRoot prompt")
    #client.expect('root\@hLinux:\~ ')
    client.expect('root@hLinux:~ ')
    
def parseTable(tableText):
    """ Parse the OpenStack cli style table output and place this in a Python List """
    table = []
    #table = None
    tableDelimitersSeen=0
    TABLE_DELIMITER='+----'

    for line in tableText.split('\n'):
        # Skip to beginning of table (+----+----+):
        if TABLE_DELIMITER in line:
            tableDelimitersSeen += 1

        if (tableDelimitersSeen == 1 or tableDelimitersSeen == 2) and not TABLE_DELIMITER in line:
            #p = re.compile('^\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+\|\s+(\S+)\s+')
            p = re.compile('[^\|]+')
            all = p.findall(line)
            all = map(lambda s: s.strip(), all)
            matches = len(all)
            if len(table) == 0:
                table = [ all ]
                #table = all
            else:
                table.append( [ all ] )
                #table.append( [ all ] )
            #print("LEN(table)=" + str(len(table)))
            #print("STR(table)=" + str(table))

    #print("TABLE[0]=<" + str(table[0]) + ">")
    #print("TABLE[1]=<" + str(table[1]) + ">")
    #print("TABLE[2]=<" + str(table[2]) + ">")

    return table

def testParseTableAndOVNames():
    """ test parseTable and interpretOvercloudNodeNames functions """
    table = parseTable(TEST_STRING)
    nodes = interpretOvercloudNodeNames(table)
    print("TEST_NODES=" + str(nodes))

def interpretOvercloudNodeNames(table):
    """ determine logical names, such as swift1, vsa2 etc for overcloud node names """
    nodes = {}

    #print("table[type " + str(type(table)) + "] has " + str(len(table)) + " rows")
    #print("table[1:][type " + str(type(table[1:])) + "] has " + str(len(table[1:])) + " rows")
    for row in table[1:]:
        row=row[0]
        #print("ROW=" + str(row))
        #print("row[type " + str(type(row)) + "] has " + str(len(row)) + " elements")
    
        name=row[1]

        ip=row[5]
        m = re.compile('ctlplane=(\S+)').match(ip)
        if m == None:
            die("Failed to find ip address in IP field <" + ip + ">")
        ip = m.group(1)

        controller_types={
            'overcloud-ce-controller-SwiftStorage':    'swift',
            'overcloud-ce-controller-controller':      'controller',
            'overcloud-ce-controller-controllerMgmt':  'controllerMgmt',
            'overcloud-ce-vsastorage':                 'vsa',
            'overcloud-ce-novacompute':                'compute',
        }

        idxname = None
        for regex, namebase in controller_types.iteritems():
            m = re.compile(regex + '(\d+)').match(name)
            if m != None:
                idxname = namebase + str(m.group(1))
                break
     
        if idxname == None:
            if VERBOSE:
                print("table[type " + str(type(table)) + "] has " + str(len(table)) + " rows")
                print("row[type " + str(type(row)) + "] has " + str(len(row)) + " elements")
                print("ROW=" + str(row))
            die("Failed to match name <" + name + ">")

        #nodes[name]=ip
        nodes[idxname]= { 'ip': ip, 'name': name, 'id': id }

    if VERBOSE:
        print("NODES=" + str(nodes))
    return nodes

def testParseTable():
    """ Test the parseTable function on TEST_STRING """
    parseTable(TEST_STRING)
    #parseTable(TEST_SHORT_STRING)

def parseUndercloudNovalist(novalist):
    """ Parse the underCloud nova list, build table of nodes with logical names, vsa1 etc. """
    #| ID        | Name          | Status | Task State | Power State | Networks   |
    # HOW TO REMOVE 'NOVA LIST'
    table = parseTable(novalist)
    nodes = interpretOvercloudNodeNames(table)
    return nodes

def runUndercloudCommand(client, cmd, stackrc, parserFn):
    """ Run the specified command on the undercloud node,
        first source specified stackrc file - if specified
        then parse the output using the parserFn function- if specified
    """
    if stackrc != None:
        STEP("sourcing " + stackrc)
        client.sendline('. ' + stackrc)
        client.expect ('[#\$] ')

    STEP(cmd)
    client.sendline(cmd)
    client.expect ('[#\$] ')
    cmdop = client.before
    print(cmdop)
    
    if parserFn != None:
        # if 'nova list' in cmd:
        parsed = parserFn(cmdop)
        return parsed

    return cmdop

def performCommand(client, COMMAND, OPT_COMMAND_ARGS=None):
    """ Run the specified COMMAND on the given client connection """
    if COMMAND == COMMAND_SHOW_UNDERCLOUD_PASSWORDS:
        client.sendline('cat /root/tripleo/tripleo-undercloud-passwords')
        client.expect ('[#\$] ')
        passwords = client.before
        print(passwords)
        return passwords

    elif COMMAND == COMMAND_SHOW_OVERCLOUD_PASSWORDS:
        client.sendline('cat /root/tripleo/tripleo-overcloud-passwords')
        client.expect ('[#\$] ')
        passwords = client.before
        print(passwords)
        return passwords

    elif COMMAND == COMMAND_UC_NOVALIST:
        table = runUndercloudCommand(client, 'nova list', '/root/stackrc', parseUndercloudNovalist)
        #print(str(table))
        return table

    elif COMMAND == COMMAND_UC_NOVALIST_ALLTENANTS:
        # Uninteresting ... shouldn't differ from 'nova list' for undercloud
        table = runUndercloudCommand(client, 'nova list --all-tenants', '/root/stackrc', parseUndercloudNovalist)
        #print(str(table))
        return table

    elif COMMAND == COMMAND_OC_NOVALIST:
        table = runUndercloudCommand(client, 'nova list', '/root/overcloud.stackrc', parseTable)
        if VERBOSE:
            print(str(table))
        return table

    elif COMMAND == COMMAND_OC_NOVALIST_ALLTENANTS:
        table = runUndercloudCommand(client, 'nova list --all-tenants', '/root/overcloud.stackrc', parseTable)
        if VERBOSE:
            print(str(table))
        return table

    elif COMMAND == COMMAND_ONALL_NODES:
        #showClient('client=', client)
        SEND_COMMANDS = 'hostname; ip a | grep 10.3; ' + OPT_COMMAND_ARGS
        client.sendline(SEND_COMMANDS)
        print("Waiting for heat-admin prompt after command '" + OPT_COMMAND_ARGS + "'") # If heat-admin:
        client.expect('[#\$] ')
        return client.before

    elif COMMAND == COMMAND_INTERACT:
        client.interact()
        return None

    else:
        die("Unknown command - " + str(COMMAND))

    #client.kill(1)
    #sys.exit(0)

def becomeRoot(client):
    """ Become root via 'sudo su -' command """
    client.expect('[#\$] ')
    client.sendline('sudo su -')
    waitOnPossibleSudoPasswordPrompt(client, CONFIG['seed_password'])
    STEP("root@SEEDHOST")

def connectToSeedVM():
    """ Connect to the seedVM (via seedhost, then as root) """
    # via ssh key directly

    client = connectToSeed()

    becomeRoot(client)
    client.sendline('ssh ' + seed_vm)
    client.expect('[#\$] ')
    STEP("root@SEED_VM")
    return client

def connectToUndercloud():
    """ Connect to the undercloud node (via seedhost/seedVM) """
    # via ssh key directly

    client = connectToSeedVM()
    #client.expect ('[#\$] ')
    client.sendline('ssh heat-admin@' + undercloud)
    STEP("heat-admin@UNDERCLOUD")
    return client

def connectToUndercloudAsRoot():
    """ Connect to the undercloud node as root (via seedhost/seedVM) """

    client = connectToUndercloud()
    becomeRoot(client)
    return client

def connectToNode(NODE):
    """ Connect to the specified node """

    if NODE == NODE_SEEDHOST:
        pass
    elif NODE == NODE_SEEDHOST_ROOT:
        client = becomeRoot(client)
    elif NODE == NODE_SEEDVM:
        client = connectToSeedVM()
    elif NODE == NODE_UNDERCLOUD:
        client = connectToUndercloud()
    elif NODE == NODE_UNDERCLOUD_ROOT:
         if client_uc_root == None:
             client_uc_root = connectToUndercloudAsRoot()
    else:
        die("NOT IMPLEMENTED NODE")

    return client
    
def enumerateNodes():
    """ Create a list of all nodes in system based on seed/undercloud + nova list of overcloud """
    global VERBOSE

    SAVE_verbose = VERBOSE
    VERBOSE = 0
    nodes = performCommand(CLIENT_UC_ROOT, COMMAND_UC_NOVALIST)
    VERBOSE = SAVE_verbose

    NODES = [ NODE_SEEDVM, NODE_UNDERCLOUD_ROOT ]
    NODE_NAMES = [ 'seedvm', 'undercloud' ]

    OC_NODE_LIST = {}
    for key, value in nodes.iteritems():
        login='heat-admin@' + value['ip']

        SKIP_KEY = False
        if INC_NODES != None:
            if value['ip'] not in INC_NODES:
                #print("Skipping: " + str(value['ip']) + " is not in INC_NODES")
                SKIP_KEY = True

        if EXC_NODES != None:
            if value['ip'] in EXC_NODES:
                #print("Skipping: " + str(value['ip']) + " is in EXC_NODES")
                SKIP_KEY = True

        if not SKIP_KEY:
            #print("Adding " + str(key) + " to OC_NODE_LIST")
            OC_NODE_LIST[key] = value

    #print("OC_NODE_LIST={" + str(OC_NODE_LIST) + "}")
    print("keys OC_NODE_LIST=[" + str(OC_NODE_LIST.keys()) + "]")
    #die("OK")

    for key, value in OC_NODE_LIST.iteritems():
        login='heat-admin@' + value['ip']

        SAVE_verbose = VERBOSE
        VERBOSE = 0

        tempclient = connectToSeedVM()
        VERBOSE = SAVE_verbose

        DEBUG(0, "Creating client cnxn to " + login + " ...")
        tempclient.sendline('ssh ' + login)
        # If heat-admin:
        print("Waiting for heat-admin prompt")
        tempclient.expect('[#\$] ')
        #tempclient.sendline('hostname')
        #tempclient.expect('[#\$] ')
        #print(tempclient.before)
        print("... done")
        
        #showClient('tempclient=', tempclient)
        NODE_NAMES.append(key)
        NODES.append( tempclient )

    return NODES

################################################################################
# Main:

args = parseArgs()
#print(args)

VERBOSE=args.VERBOSE

COMMAND_ONALL_NODES_ARGS=args.COMMAND_ONALL_NODES_ARGS

INC_NODES=args.INC_NODES
EXC_NODES=args.EXC_NODES

NODES=args.NODES
if NODES==None:
    if COMMAND_ONALL_NODES_ARGS != None:
        NODES = [ NODE_TO_ENUMERATE ]
    else:
        NODES = [ NODE_SEEDHOST ]

COMMANDS=args.COMMANDS
if COMMANDS == None:
    if COMMAND_ONALL_NODES_ARGS != None:
        COMMANDS = [ COMMAND_ONALL_NODES ]
    else:
        COMMANDS = [ COMMAND_INTERACT ]

if args.PLATFORM:
    PLATFORM = args.PLATFORM

USE_KEYS=args.USE_KEYS

CONFIG = readConfig(section=PLATFORM)
if USE_KEYS:
    CONFIG['seed_password']='';

seed_vm =    CONFIG['seed_vm']
undercloud = CONFIG['undercloud']

SAVE_verbose = VERBOSE
VERBOSE = 0
print("Creating initial client cnxns to seed/seedVM/undercloud ...")
CLIENT_SEED    = connectToSeed()
CLIENT_SEEDVM  = connectToSeedVM()
CLIENT_UC      = connectToUndercloud()
CLIENT_UC_ROOT = connectToUndercloudAsRoot()
VERBOSE = SAVE_verbose
print("... Done")

if NODES[0] == NODE_TO_ENUMERATE:
    #NODES = QUIETEN(0, enumerateNodes)
    SAVE_verbose = VERBOSE
    VERBOSE = 0
    NODES = enumerateNodes()
    VERBOSE = SAVE_verbose

for NODE in NODES:

    for COMMAND in COMMANDS:

        if COMMAND == COMMAND_SHOW_UNDERCLOUD_PASSWORDS:
            performCommand(CLIENT_SEEDVM, COMMAND)

        elif COMMAND == COMMAND_SHOW_OVERCLOUD_PASSWORDS:
            performCommand(CLIENT_SEEDVM, COMMAND)

        elif COMMAND == COMMAND_UC_NOVALIST:
            performCommand(CLIENT_UC_ROOT, COMMAND)

        elif COMMAND == COMMAND_UC_NOVALIST_ALLTENANTS:
            performCommand(CLIENT_UC_ROOT, COMMAND)

        elif COMMAND == COMMAND_OC_NOVALIST:
            performCommand(CLIENT_UC_ROOT, COMMAND)
    
        elif COMMAND == COMMAND_OC_NOVALIST_ALLTENANTS:
            performCommand(CLIENT_UC_ROOT, COMMAND)
    
        elif COMMAND == COMMAND_ONALL_NODES:
            if NODE == NODE_SEEDVM:
                CLIENT=CLIENT_SEEDVM
            elif NODE == NODE_UNDERCLOUD_ROOT:
                CLIENT=CLIENT_UC_ROOT
            else:
                CLIENT=NODE

            cmdop = performCommand(CLIENT, COMMAND, COMMAND_ONALL_NODES_ARGS)
            print("COMMAND OP='" + str(cmdop) + "'")

        elif COMMAND == COMMAND_INTERACT:
            client.send('print("Hello from seed_host - now over to you!")\n')
            client.interact()
            die("TODO")
            pass

        else:
            die("TODO - untreated command in NODES loop")

#testParseTableAndOVNames()
#testParseTable()
#die("OK")


#print(client.after, end='')
#client.send('print("Hello from seed_host - now over to you!")\n')
#client.interact()

