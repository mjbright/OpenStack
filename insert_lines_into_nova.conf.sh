
NOVA_CONF=/etc/nova/nova.conf
NOVA_CONF_ORIG=/etc/nova/nova.conf.orig

QUOTA_CORES_LINE=quota_cores=-1
#QUOTA_INSTANCES_LINE=quota_instances=10

##############################################################################
# Functions:

PROG=$0
# FATAL: Exit with error message and non-zero return code
FATAL() {
    echo "$PROG: FATAL - $*" >&2
    exit 1
}

##############################################################################
# Cmd-line args: TODO

while [ ! -z "$1" ];do
    case $1 in
#        -0) VERBOSE=0;;
#        -v) let VERBOSE=VERBOSE=1;;
#        #-bg) BACKGROUND=1;;
#        #-fg) BACKGROUND=0;;
        *) FATAL "Unknown option: $1";;
    esac
    shift
done

##############################################################################
# Main:

[ ! -f $NOVA_CONF_ORIG ] && cp $NOVA_CONF $NOVA_CONF_ORIG

diff $NOVA_CONF $NOVA_CONF_ORIG

grep quota_cores $NOVA_CONF || {
    echo "No quota_cores line in $NOVA_CONF, adding $QUOTA_CORES_LINE";
    sudo sed "/\[DEFAULT\]/a\
$QUOTA_CORES_LINE
" -i.bak2 $NOVA_CONF;
}
#&& echo "quota_cores line already present";

#grep quota_instances $NOVA_CONF || {
#    echo "No quota_instances line in $NOVA_CONF, adding $QUOTA_INSTANCES_LINE";
#    sudo sed "/\[DEFAULT\]/a\
#$QUOTA_INSTANCES_LINE
#" -i.bak2 $NOVA_CONF;
#}
#&& echo "quota_instances line already present";

ls -altr $NOVA_CONF $NOVA_CONF_ORIG
diff $NOVA_CONF $NOVA_CONF_ORIG

