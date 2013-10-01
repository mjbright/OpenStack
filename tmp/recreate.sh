
SCRIPTS_DIR=/home/mjb/src/git/OpenStack
DEVSTACK_DIR=/home/mjb/src/git/devstack

IMAGE="cirros-0.3.1-x86_64-uec"

#nova flavor-create <name> <id> <ram> <disk> <vcpus>
MY_FLAVOR=myflav
MY_FLAVOR_ID=20
MY_FLAVOR_ARGS="64 0 2"

VERBOSE=1
BACKGROUND=1

##############################################################################
# Functions:

PROG=$0
# FATAL: Exit with error message and non-zero return code
FATAL() {
    echo "$PROG: FATAL - $*" >&2
    exit 1
}

# debug: Output debug messae if VERBOSE set to non-zero
debug() {
    [ $VERBOSE -ne 0 ] && echo "DEBUG: $*" >&2
}

restart_nova_api() {
    $SCRIPTS_DIR/restart_nova_api.sh
}

set_nova_conf() {
    $SCRIPTS_DIR/insert_lines_into_nova.conf.sh
}

normal_user() {
    . $DEVSTACK_DIR/openrc
}

admin_user() {
    . $DEVSTACK_DIR/openrc admin
}

create_flavor() {
    nova flavor-list
    #nova flavor-create 'm1.tiny' 20 64 0 1 # id RAM disk vcpus
    nova flavor-create $MY_FLAVOR $MY_FLAVOR_ID $MY_FLAVOR_ARGS
    nova flavor-list
}

create_1image() {
    nova boot --image $IMAGE --flavor $MY_FLAVOR_ID testg1
    nova list
}

create_12images() {
    nova boot --image $IMAGE --num-instances 12 --flavor $MY_FLAVOR_ID testg12
    nova list
}

##############################################################################
# Cmd-line args:

while [ ! -z "$1" ];do
    case $1 in
        -0) VERBOSE=0;;
        -v) let VERBOSE=VERBOSE=1;;
        -x) set -x;;
        #-bg) BACKGROUND=1;;
        #-fg) BACKGROUND=0;;
        *) FATAL "Unknown option: $1";;
    esac
    shift
done



##############################################################################
# Main:

## if [ -z "$IMAGE_ID" ];then
## IMAGE_ID=`nova image-list | grep " cirros-0.3.1-x86_64-uec " | awk '{ print $2;}'`
## fi

#kill_devstack
#normal_user
admin_user
#create_flavor
create_1image

exit 0

set_nova_conf
restart_nova_api


exit 0
##############################################################################




   41  ll
   42  . ../devstack/openrc 
   43  ./novaclient_list.py 
   44  #git rm MJ
   45  ll ~/MJB.files.tar 
   46  git rm MJB.files.tar 
   47  git status
   48  git status  -v
   49  svn diff
   50  git diff
   51  git status
   52  ll
   53  git add novaclient_list.py
   54  vi novaclient_list.py
   55  git push
   56  git status
   57  git loh
   58  git log
   59  git commit
   60  git status
   61  git add novaclient_list.py
   62  git status
   63  git commit -m "First checkin of simple novaclient to list flavours/images/instances"
   64  git push
   65  git status
   66  ./novaclient_list.py 
   67  ll
   68  vi novaclient_list.py
   69  ./novaclient_list.py 
   70  git commit -a -m "Changed message to say INSTANCES(servers) as I think in instances ..."
   71  git config --global user.name mjbright
   72  git config --global user.email github@mjbright.net
   73  git push
   74  git status
   75  git log
   76  ./novaclient_list.py 
   77  vi novaclient_list.py
   78  ./novaclient_list.py 
   79  vi novaclient_list.py
   80  ./novaclient_list.py 
   81  vi novaclient_list.py
   82  ./novaclient_list.py 
   83  vi novaclient_list.py
   84  ./novaclient_list.py 
   85  vi novaclient_list.py
   86  ./novaclient_list.py 
   87  vi novaclient_list.py
   88  ./novaclient_list.py 
   89  git commit -m "Cleaned up client code - added comments/reduced imports to minimum needed"
   90  git push
   93  nova flavor-list

  nova image-list

  118  nova list
  119  nova help | grep list
  120  nova list
  121  env | grep OS
  122  . ../devstack/openrc 
  123  nova list
  124  env | grep OS
  125  . ../devstack/openrc demo
  126  nova list
  127  ./novaclient_list.py 
  128  nova list
  129  vi ../devstack/openrc 
  130  . ../devstack/openrc demo demo
  131  nova list
  132  . ../devstack/openrc admin demo
  133  nova list
  134  nova show test1
  135  nova show test1_2
  136  nova flavor-list
  137  nova show test1_2
  138  history
  139  history | grep stack
  140  history
  141  history > ~/history.flavor-list.txt
  142  vi ~/history.flavor-list.txt
  143  grep -i quota ~/history.flavor-list.txt 
  144  ll -tr ~/
  145  ll ~/MJB.files.tar 
  146  tar tf ~/MJB.files.tar 
  147  tar tf ~/MJB.files.tar  | less
  148  ll ~/LOG1 
  149  grep -i quota ~/LOG1 
  150  mv ~/LOG1 ~/history.quota.txt 
  151  mkdir ~/HISTORY
  152  cp -a ~/history.* ~/HISTORY/
  153  nova quota-show
  154  Hello, 
  155  I am currently working in the morning French time, and on medical leave in the afternoons.
  156  For Solutioning, please contact Nicolas Prost.
  157  For any urgent topic related to CSE program, please contact Jayanta Mukherjee, 
  158  Otherwise I will answer you in the morning.
  159  Thanks
  160  Best regards
  161  Catherine Leretaille
  162  grep -i quota ~/LOG1 
  163  grep -i quota ~/history.quota.txt 
  164  nova quota-show
  165  vi ~/history.quota.txt 
  166  keystone tenant-list
  167  vi ~/stopnova.sh
  168  chmod +x ~/stopnova.sh
  169  ps -fade | grep nova
  170  ~/stopnova.sh
  171  sudo ~/stopnova.sh
  172  ps -fade | grep nova
  173  sudo ~/stopnova.sh
  174  cat ~/stopnova.sh 
  175  find /opt/stack/ -name 'nova.conf'
  176  find /opt/stack/ -iname 'nova.conf'
  177  sudo find /opt/stack/ -iname 'nova.conf'
  178  sudo find /etc/ -iname 'nova.conf'
  179  ll /etc/nova/nova.conf 
  180  sudo vi /etc/nova/nova.conf 
  181  #sudo vi /etc/nova/nova.conf 
  182  ll
  183  ll src/git/
  184  cd src/git/
  185  ll
  186  git clone http://github.com/mjbright/OpenStack
  187  cd OpenStack/
  188  ll
  189  tar xvf MJB.files.tar 
  190  ll
  191  #mb LOG1 
  192  mv MJB.files.tar LOG1  ~/
  193  ll
  194  ll home/mjb/src/git/devstack/localrc 
  195  mv home/mjb/src/git/devstack/localrc  ../devstack/localrc.2
  196  sudo mv home/mjb/src/git/devstack/localrc  ../devstack/localrc.2
  197  ll
  198  ll home/mjb/src/git/devstack/
  199  rmdir home/mjb/src/git/devstack/
  200  ll home/mjb/src/git/
  201  ll home/mjb/src/git/OpenStack/
  202  mv  home/mjb/src/git/OpenStack/novaclient_* .
  203  ll
  204  rm -rf home/
  205  ll
  206  ./novaclient_list.py 
  207  ll ../devstack/openrc 
  208  . ../devstack/openrc 
  209  ./novaclient_list.py 
  210  cd ../devstack/
  211  ps -fade | grep stack
  212  sudo /etc/init.d/apache2 stop
  213  ps -fade | grep stack
  214  sudo ./stack.sh 
  215  ps -fade | grep stack
  216  sudo kill -9 10091 10092 
  217  ps -fade | grep stack
  218  sudo ./unstack.sh 
  219  ps -fade | grep stack
  220  vi localrc
  221  sudo cp localrc localrc.offline
  222  ll localrc*
  223  cat localrc.
  224  cat localrc.2
  225  sudo vi localrc
  226  sudo ./stack.sh 
  227  screen -x stack
  228  sudo ./unstack.sh 
  229  screen -rs
  230  screen -s
  231  sudo ./unstack.sh 
  232  sudo ./stack.sh 
  233  screen -x stack
  234  screen -x
  235  screen -r
  236  ps -fade | grep screen
  237  #ll /tmp/
  238  sudo ./stack.sh 
  239  cat localrc
  240  vi stack.sh 
  241  screen -ls
  242  vi stack.sh 
  243  sudo vi stack.sh 
  244  sudo ./stack.sh 
  245  sudo vi stack.sh 
  246  sudo ./stack.sh 
  247  ll /var/run/screen/
  248  ll /var/run/screen/S-stack/
  249  sudo ls -altr /var/run/screen/S-stack/
  250  sudo ls -altr /var/run/screen/S-stack/4454.stack
  251  ps -fade | grep 4454
  252  sudo rm /var/run/screen/S-stack/4454.stack
  253  sudo ./stack.sh 
  254  cat localrc
  255  ll -tr
  256  cp -a localrc localrc.grizzly
  257  sudo cp localrc localrc.grizzly
  258  sudo vi localrc
  259  ps -fade | grep stack
  260  sudo ./unstack.sh 
  261  history
  262  sudo ./stack.sh 
  263  cd ../OpenStack/
  264  ll
  265  cp /tmp/restart_nova_api.sh .
  266  git add restart_nova_api.sh
  267  git commit -m "Added restart_nova_api script as a helper"
  268  git push
  269  vi restart_nova_api.sh 
  270  git add restart_nova_api.sh 
  271  git commit -m "Tidied up restart script, added comments"
  272  git push
  273  cd -
  274  vi ../OpenStack/restart_nova_api.sh 
  275  #../OpenStack/restart_nova_api.sh 
  276  ll /etc/nova/nova.conf
  277  vi /etc/nova/nova.conf
  278  sudo vi /etc/nova/nova.conf
  279  nova boot --image $IMAGE --num-instances 12 --flavor 42 mikex
  280  . openrc 
  281  nova boot --image $IMAGE --num-instances 12 --flavor 42 mikex
  282  ps -fade | grep stack
  283  cd ~/src/git/devstack/
  284  ll
  285  vi localrc
  286  ll -tr
  287  #vi localrc
  288  date
  289  #vi localrc
  290  ll -tr ../
  291  ll -tr ../OpenStack/
  292  ll -tr
  293  vi localrc
  294  #sudo ./stack.sh 
  295  vi /etc/nova/nova.conf
  296  sudo ./stack.sh 
  297  nova list
  298  . openrc 
  299  nova list
  300  sudo stack
  301  sudo -u stack
  302  sudo -u stack bash
  303  ps -fade | grep nova
  304  sudo -u stack
  305  su - stack
  306  grep stack /etc/passwd
  307  cd ~/src/git/devstack/
  308  . openrc 
  309  nova list
  310  /tmp/restart_nova_api.sh 
  311  nova boot --image $IMAGE --num-instances 12 --flavor 100 mikex
  312  nova list
  313  nova flavor-list
  314  nova boot --image $IMAGE --num-instances 12 --flavor 100 mikex
  315  nova image-list
  316  nova boot --image $IMAGE --num-instances 1 --flavor 100 mikex
  317  nova boot --image $IMAGE --flavor 100 mikex
  319  /tmp/restart_nova_api.sh 
  320  nova boot --image $IMAGE --num-instances 12 --flavor 20 coretestx
  321  ll /etc/nova/nova.conf
  322  cp  /etc/nova/nova.conf /etc/nova/nova.conf.mine
  323  sudo cp  /etc/nova/nova.conf /etc/nova/nova.conf.mine

