
VERBOSE=""

PROJECT=nova
FIND_FILTER='*.py'
echo "FIND=$FIND_FILTER"

########################################
# Functions:

PROG=$0
# FATAL: Exit with error message and non-zero return code
FATAL() {
    echo "$PROG: FATAL - $*" >&2
    exit 1
}

########################################
# Args:

while [ ! -z "$1" ];do
    case $1 in
        -nova)    PROJECT=nova;;
        -horizon) PROJECT=horizon;;
        -cinder) PROJECT=cinder;;
        -swift) PROJECT=swift;;
        -glance) PROJECT=glance;;

        -a)       FIND_FILTER='';;

        -v)       VERBOSE="v";;
        -x)       set -x;;
        +x)       set +x;;

        *) FATAL "Unknown option: '$1'";;
    esac
    shift
done

########################################
# Main:

PROJECT_DIR=/opt/stack/$PROJECT

if [ ! -z "$FIND_FILTER" ];then
    echo "Creating temp cpio archive of $PROJECT_DIR (*.py):"
else
    FIND_FILTER='*'
    echo "Creating tar archive of $PROJECT_DIR (FULL):"
    sudo tar c${VERBOSE}f - ${PROJECT_DIR}/ | \
        bzip2 -9 > /tmp/opt.stack.${PROJECT}.tbz2 
    ls -al /tmp/opt.stack.${PROJECT}.tbz2 
    exit $?
fi

#find ${PROJECT_DIR}/ $FIND_NAME_OPT | \
find ${PROJECT_DIR}/ -name "$FIND_FILTER" | \
    sudo cpio -oa${VERBOSE} | \
    bzip2 -9 > /tmp/opt.stack.${PROJECT}.cpio.tbz2

ls -al /tmp/opt.stack.${PROJECT}.cpio.tbz2 
set +x
exit 0

[ -d /tmp/cpio.op ] && sudo rm -rf /tmp/cpio.op
[ -d /tmp/cpio.op ] && FATAL "Failed to 'rm -rf /tmp/cpio.op'"
mkdir /tmp/cpio.op
cd /tmp/cpio.op

echo "Unpacking temp cpio archive of $PROJECT_DIR under ${PWD}:"
bzip2 -d < ../opt.stack.${PROJECT}.cpio.tbz2 | \
    cpio -idum${VERBOSE} --no-absolute-filenames

echo "Creating tar archive of $PROJECT_DIR (*.py):"
tar c${VERBOSE}f - ./opt/ | \
    bzip2 -9 > ../opt.stack.${PROJECT}.tbz2 

ls -al /tmp/opt.stack.${PROJECT}.tbz2 



