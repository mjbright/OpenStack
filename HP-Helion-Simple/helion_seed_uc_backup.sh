
DATETIME=$(date +%Y-%m-%d_%Hh)
START=$(date +%S)

BACKUP_DIR=/root/BACKUP.RESTORE/backups/${DATETIME}
LOGFILE=${BACKUP_DIR}/${DATETIME}.log

SCRIPTS=/root/tripleo/tripleo-incubator/scripts/

SEED_QCOW=/var/lib/libvirt/images/seed.qcow2

[ ! -d $BACKUP_DIR ] && mkdir -p $BACKUP_DIR

[ -z "$1" ] && { exec $0 -logging |& tee $LOGFILE; exit; }

# Assuming no race condition on exec/LOGFILE/date:
echo "Logging to $LOGFILE"

die() {
    echo "$0: die - $*" >&2
    echo "Output Logged to $LOGFILE"
    END=$(date +%S); echo "Took $((END-START)) secs"
    exit 1
}

SEED_QCOW_SIZE=$(wc -c < $SEED_QCOW)
SEED_QCOW_SIZE_MB=$(( SEED_QCOW_SIZE / 1024 / 1024 ))

DF_KBYTES_AVAIL=$(df /root/ | tail -1 | awk '{ print $4; }')
DF_KBYTES_AVAIL_MB=$(( DF_KBYTES_AVAIL / 1024 ))

NINETYPC_AVAIL=$(( 900 * $DF_KBYTES_AVAIL ))
NINETYPC_AVAIL_MB=$(( NINETYPC_AVAIL / 1024 / 1024 ))

echo
echo "SEED_QCOW_SIZE[MBy]=$SEED_QCOW_SIZE_MB"
echo "DF_KBYTES_AVAIL[MBy]=$DF_KBYTES_AVAIL_MB"
echo "NINETYPC_AVAIL[MBy]=$NINETYPC_AVAIL_MB"
echo
if [ $NINETYPC_AVAIL_MB -le $SEED_QCOW_SIZE_MB ];then
    die "Insufficient space for seed VM backup (${NINETYPC_AVAIL_MB}MBy < seedVM ${SEED_QCOW_SIZE_MB}MBy)"
fi
echo ; echo "Sufficient disk space for seed.qcow backup - proceeding ..."

$SCRIPTS/hp_ced_backup.sh --seed -f $BACKUP_DIR

DF_KBYTES_AVAIL=$(df /root/ | tail -1 | awk '{ print $4; }')
DF_KBYTES_AVAIL_MB=$(( DF_KBYTES_AVAIL / 1024 ))

NINETYPC_AVAIL=$(( 900 * $DF_KBYTES_AVAIL ))
NINETYPC_AVAIL_MB=$(( NINETYPC_AVAIL / 1024 / 1024 ))

EXTIMATED_UNDERCLOUD_SIZE_MB="30000"

echo
echo "EXTIMATED_UNDERCLOUD_SIZE_MB[MBy]=$EXTIMATED_UNDERCLOUD_SIZE_MB"
echo "DF_KBYTES_AVAIL[MBy]=$DF_KBYTES_AVAIL_MB"
echo "NINETYPC_AVAIL[MBy]=$NINETYPC_AVAIL_MB"
echo
if [ $NINETYPC_AVAIL_MB -le $EXTIMATED_UNDERCLOUD_SIZE_MB ];then
    die "Insufficient space for UC backup (${NINETYPC_AVAIL_MB}MBy < estimated UC backup size ${EXTIMATED_UNDERCLOUD_SIZE_MB}MBy)"
fi
echo ; echo "Sufficient disk space for underloud backup - proceeding ..."

$SCRIPTS/hp_ced_backup.sh --undercloud -f $BACKUP_DIR

df

echo "Output Logged to $LOGFILE"
ls -altr $LOGFILE

END=$(date +%S); echo "Took $((END-START)) secs"
exit 0

