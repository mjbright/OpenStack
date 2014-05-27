
DIR=${0%/*}
. $DIR/OpenStack.fns

ARG_NAME=""
NAME=""
GLANCE_IMAGE_FILE=""

#IFORMAT=qcow2
OFORMAT=vmdk

################################################################################
# Fns:

die() {
    echo "$0: die - $*" >&2
    exit 1
}

[ -z "$1" ] && die "Missing arguments"

################################################################################
# Args:

while [ ! -z "$1" ];do
    case $1 in
        # Set image filename to use:
        -df) shift; GLANCE_IMAGE_FILE="$1";;

        # Set image name to search for:
        *) [ ! -z "$ARG_NAME" ] &&
               die "NAME already set to '$ARG_NAME' - unknown option '$1'";
           ARG_NAME=$1;;
    esac
    shift
done

################################################################################
# Main:

echo
echo "Getting image info for '$ARG_NAME' ..."
GLANCE_ID=`getGlanceImageId "$ARG_NAME"`
[ -z "$GLANCE_ID" ] && {
    glance --insecure list;
    die "Failed to get glance image id for '$ARG_NAME'";
}
echo "Image ID='$GLANCE_ID'"

GLANCE_NAME=`getGlanceImageName "$ARG_NAME"`
[ -z "$GLANCE_NAME" ] && {
    glance --insecure list;
    die "Failed to get glance image name for '$ARG_NAME'";
}
echo "Image NAME='$GLANCE_NAME'"

GLANCE_DISKFMT=`getGlanceImageDiskFormat "$ARG_NAME"`
[ -z "$GLANCE_DISKFMT" ] && {
    glance --insecure list;
    die "Failed to get glance image disk format for '$ARG_NAME'";
}
echo "Image Disk format='$GLANCE_DISKFMT'"

GLANCE_CONTAINERFMT=`getGlanceImageContainerFormat "$ARG_NAME"`
[ -z "$GLANCE_CONTAINERFMT" ] && {
    glance --insecure list;
    die "Failed to get glance image container format for '$ARG_NAME'";
}
echo "Image Container format='$GLANCE_CONTAINERFMT'"

GLANCE_SIZE=`getGlanceImageSize "$ARG_NAME"`
[ -z "$GLANCE_SIZE" ] && {
    glance --insecure list;
    die "Failed to get glance image size for '$ARG_NAME'";
}
echo "Image Size='$GLANCE_SIZE'"

[ -z "$GLANCE_IMAGE_FILE" ] &&
    GLANCE_IMAGE_FILE="GLANCE.TMP.${GLANCE_NAME}.${GLANCE_DISKFMT}"

[ -z "$GLANCE_IMAGE_FILE2" ] &&
    GLANCE_IMAGE_FILE2="GLANCE.TMP.${GLANCE_NAME}.${OFORMAT}"


echo
echo "Downloading '$GLANCE_NAME' image ($GLANCE_ID) size ($GLANCE_SIZE) ..."
#time glance --insecure image-download daf345-a0bd-4a6b-96f4-fed18a8203ba > windows-server-2012-r2.qcow2
time glance --insecure image-download $GLANCE_ID > $GLANCE_IMAGE_FILE

echo
echo "Converting image to '$OFORMAT' format ..."
#time qemu-img convert -f raw -O vmdk windows-server-2012-r2.qcow2 windows-server-2012-r2.vmdk
time qemu-img convert -f raw -O $OFORMAT $GLANCE_IMAGE_FILE $GLANCE_IMAGE_FILE2

echo
echo "Uploading '$GLANCE_NAME' image in $OFORMAT format size $(wc -c $GLANCE_IMAGE_FILE2) ..."
#time glance --insecure image-create --name windows-server-2012-r2 --disk-format=vmdk --container-format=bare < windows-server-2012-r2.vmdk
time glance --insecure image-create --name $GLANCE_NAME --disk-format=$OFORMAT --container-format=$GLANCE_CONTAINERFMT < $GLANCE_IMAGE_FILE2


