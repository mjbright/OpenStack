
VERBOSE="v"
VERBOSE=""

PROJECT=nova

PROJECT_DIR=/opt/stack/$PROJECT

echo "Creating temp cpio archive of $PROJECT_DIR (*.py):"
find ${PROJECT_DIR}/ -name '*.py' | \
    cpio -oa${VERBOSE} | \
    bzip2 -9 > /tmp/opt.stack.${PROJECT}.cpio.tbz2

ls -al /tmp/opt.stack.${PROJECT}.cpio.tbz2 

[ -d /tmp/cpio.op ] && rm -rf /tmp/cpio.op
mkdir /tmp/cpio.op
cd /tmp/cpio.op

echo "Unpacking temp cpio archive of $PROJECT_DIR under ${PWD}:"
bzip2 -d < ../opt.stack.${PROJECT}.cpio.tbz2 | \
    cpio -idum${VERBOSE} --no-absolute-filenames

echo "Creating tar archive of $PROJECT_DIR (*.py):"
tar c${VERBOSE}f - ./opt/ | \
    bzip2 -9 > ../opt.stack.${PROJECT}.tbz2 

ls -al /tmp/opt.stack.${PROJECT}.tbz2 



