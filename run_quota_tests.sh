
# Script to run nova quota tests under DevStack

ROOT=/opt/stack
PROJECT=nova

CREATE_LIST=0

################################################################################
# functions:

PROG=$0
die() {
    echo "$PROG: die - $*" >&1
    exit 1
}

################################################################################
# args:

while [ ! -z "$1" ];do
    case $1 in
        -root) shift;ROOT=$1;;

        -ci*) PROJECT=cinder;;
        -gl*) PROJECT=glance;;
        -ho*) PROJECT=horizon;;
        -ke*) PROJECT=keystone;;
        -no*) PROJECT=nova;;
        -os*) PROJECT=oslo;;

        -L) CREATE_LIST=1;;

        *) die "Unknown option '$1'";;
    esac
    shift
done

################################################################################
# main:

# Note start time in secs:
START=`date +%s`

# Change to nova dir:
cd $ROOT/$PROJECT

# Run *all* tests under Python 2.7:
#time tox -epy27

# Extract list of compute_api tests, then extract exceed(quota) tests:
[ $CREATE_LIST -ne 0 ] && {
    echo "Creating list of (compute-api-quota) tests to perform:";

    testr list-tests compute_api > compute-api.tests;
    grep -i exceed compute-api.tests  > compute-api-quota.tests;

    echo "Adding QuotaIntegration tests to list:";
    testr list-tests | grep -i QuotaIntegration > quota-integ.tests;
    cat compute-api-quota.tests quota-integ.tests > my-quota.tests;

    echo "Created list of " `wc -l < my-quota.tests` " tests";
}


# Run list of quota tests:
#python -m testtools.run discover --load-list compute-api-quota.tests
python -m testtools.run discover --load-list my-quota.tests

################################################################################
# end:

# Calculate elapsed time in secs:
END=`date +%s`
let TIME=END-START

echo "Took $TIME secs"




