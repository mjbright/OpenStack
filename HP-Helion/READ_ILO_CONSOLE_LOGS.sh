
SPY=$HOME/z/bin/Deployed/spy.pl

RAW=OLD/OLD2/2014-10-22-10h15m59.i118.textcons.raw.log

################################################################################
# Functions:

unescapeILO() {
    perl -ne '
    s/\x1b\x5b[0-9]m//g;
    s/\x1b\x5b[0-9]J//g;
    s/\x1b\x5bH//g;
    s/\x1b\x5b1;1H//g;

    s/\x1b\x5b14[23];[0-9]*H//g;
    s/\x1b\x5b[0-9]*;[0-9]*H//g;

    s/\x1b\x5b[0-9]*;1H//g;
    s/\x1b\x5b0;25;37;40m/\n/g;
    s/\x1b\x5b0;25;3[0-9];40m/\n/g;

    #UNCAUGHT_ESC:1;25;34;40m - 2014-12-04
    s/\x1b\x5b1;25;3[0-9];40m/\n/g;

    s/\x1b\x5b +\x1b\x5b/\x1b\x5b/g;

    s/\x1b\x5b/\nUNCAUGHT_ESC:/g;

    if (!/^\s*$/) {
        print "$_";
        #next; # Skip blank lines
    }
  '
}

die() {
    echo "$0: die - $*" >&2
    exit 1
}

getDir() {
    [ -z "$2" ] && DIR=$(ls -1trd 201*/ | tail -1) || DIR="$2"
}

getLastFile() {
    RAW=$(ls -1tr ${DIR}/*.raw | tail -1)
}

getLastDirFile() {
    getDir $*
    RAW=$(ls -1tr ${DIR}/*.raw | tail -1)
}

################################################################################
# Main:

#[ ! -z "$1" ] && RAW="$1"
#[ -z "$1" ] && set -- $RAW

[ -z "$1" ] && set -- -LAST

while [ ! -z "$1" ];do
    case $1 in
        -)
            unescapeILO;; # stdin -> stdout
        -TAIL)
            # Get directory name either as argument "$1" or as last updated dir:
            # Get filename of last modified .raw file:
            getDir $*

            declare -A LINE_COUNTS
            declare -A BYTE_COUNTS
            LAST_FILE=""
            while true; do
                getLastFile $*
                BYTE_COUNT=$(wc -c < $RAW)
                [ $BYTE_COUNT != "${BYTE_COUNTS[$RAW]}" ] && {
                    $0 $RAW 2>/dev/null
                    LINE_COUNT=$(wc -l < ${RAW}.OP)
                    [ $LINE_COUNT != "${LINE_COUNTS[$RAW]}" ] && {
                        #let OLD_LINE_COUNT=${LINE_COUNTS[$RAW]:0}
                        let LINES=$LINE_COUNT-${LINE_COUNTS[$RAW]:-0}

                        FILE=${RAW}.OP
                        [ "$FILE" != "$LAST_FILE" ] && {
                            echo; echo "======== [ILO $FILE] ========"
                            LAST_FILE=$FILE
                        }

                        tail -$LINES ${RAW}.OP
                    }
                
                    LINE_COUNTS[$RAW]=$LINE_COUNT;
                    BYTE_COUNTS[$RAW]=$BYTE_COUNT;
                }
                sleep 1
            done
            
            ;;

        -LAST)
            # Get directory name either as argument "$1" or as last updated dir:
            # Get filename of last modified .raw file:
            getLastDirFile $*
            $0 $RAW
            tail -100 ${RAW}.OP
            ;;
        *)
            #[ ! -f $1 ] && die "No such i/p file '$1'";
            [ -f $1 ] && {
                #echo "cat $1 | unescapeILO > ${1}.OP;"
                unescapeILO < $1 > ${1}.OP;
                wc -l $1 ${1}.OP >&2;
                break;
                }
            [ -d $1 ] && {
                for RAW in $1/*.raw;do
                    [ -s $RAW ] && $0 $RAW
                done
                break;
            }
            #[ ! -f $1 ] && die "No such i/p file '$1'";
            die "No such i/p file or dir '$1'";
            ;;
             
    esac
    shift
done


exit 0

ORIGINAL:
===========
0x00: 74 65 78 74 63 6f 6e 73 0d 0d 0a 0d 0a 53 74 61  textcons.....Sta
0x10: 72 74 69 6e 67 20 54 65 78 74 20 43 6f 6e 73 6f  rting Text Conso
0x20: 6c 65 2e 0d 0a 50 72 65 73 73 20 27 45 73 63 20  le...Press 'Esc 
0x30: 28 27 20 74 6f 20 72 65 74 75 72 6e 20 74 6f 20  (' to return to 
0x40: 74 68 65 20 43 4c 49 20 53 65 73 73 69 6f 6e 2e  the CLI Session.
0x50: 0d 0a 0d 0a 1b 5b 30 6d 1b 5b 31 6d 1b 5b 30 6d  .....[0m.[1m.[0m
0x60: 1b 5b 31 6d 1b 5b 32 4a 1b 5b 48 1b 5b 31 34 32  .[1m.[2J.[H.[142
0x70: 3b 31 48 1b 5b 31 3b 31 48 1b 5b 30 3b 32 35 3b  ;1H.[1;1H.[0;25;
0x80: 33 37 3b 34 30 6d 20 20 20 20 20 20 20 20 20 20  37;40m          
0x90: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xa0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xb0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xc0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xd0: 20 20 20 20 20 20 1b 5b 32 3b 31 48 1b 5b 30 3b        .[2;1H.[0;
0xe0: 32 35 3b 33 37 3b 34 30 6d 75 6e 64 65 72 63 6c  25;37;40mundercl
0xf0: 6f 75 64 2d 75 6e 64 65 72 63 6c 6f 75 64 2d 37  oud-undercloud-7
Offset: 0x100
0x00: 33 34 76 71 78 36 74 7a 63 33 7a 20 6c 6f 67 69  34vqx6tzc3z logi
0x10: 6e 3a 20 5b 20 20 20 38 32 2e 32 37 37 33 33 30  n: [   82.277330
0x20: 5d 20 69 6e 69 74 3a 20 55 6e 61 62 6c 65 20 74  ] init: Unable t
0x30: 6f 20 63 6f 6e 6e 65 63 74 1b 5b 33 3b 31 48 1b  o connect.[3;1H.
0x40: 5b 30 3b 32 35 3b 33 37 3b 34 30 6d 20 74 6f 20  [0;25;37;40m to 
0x50: 74 68 65 20 44 2d 42 75 73 20 73 79 73 74 65 6d  the D-Bus system
0x60: 20 62 75 73 3a 20 46 61 69 6c 65 64 20 74 6f 20   bus: Failed to 
0x70: 63 6f 6e 6e 65 63 74 20 74 6f 20 73 6f 63 6b 65  connect to socke
0x80: 74 20 2f 76 61 72 2f 72 75 6e 2f 64 62 75 73 2f  t /var/run/dbus/
0x90: 73 79 73 74 65 6d 5f 62 75 73 5f 73 1b 5b 34 3b  system_bus_s.[4;
0xa0: 31 48 1b 5b 30 3b 32 35 3b 33 37 3b 34 30 6d 6f  1H.[0;25;37;40mo
0xb0: 63 6b 65 74 3a 20 4e 6f 20 73 75 63 68 20 66 69  cket: No such fi
0xc0: 6c 65 20 6f 72 20 64 69 72 65 63 74 6f 72 79 20  le or directory 
0xd0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xe0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xf0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 1b        


OP:
===========
0x00: 4f 50 3a 74 65 78 74 63 6f 6e 73 0d 0d 0a 4f 50  OP:textcons...OP
0x10: 3a 0d 0a 4f 50 3a 53 74 61 72 74 69 6e 67 20 54  :..OP:Starting T
0x20: 65 78 74 20 43 6f 6e 73 6f 6c 65 2e 0d 0a 4f 50  ext Console...OP
0x30: 3a 50 72 65 73 73 20 27 45 73 63 20 28 27 20 74  :Press 'Esc (' t
0x40: 6f 20 72 65 74 75 72 6e 20 74 6f 20 74 68 65 20  o return to the 
0x50: 43 4c 49 20 53 65 73 73 69 6f 6e 2e 0d 0a 4f 50  CLI Session...OP
0x60: 3a 0d 0a 4f 50 3a 20 20 20 20 20 20 20 20 20 20  :..OP:          
0x70: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0x80: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0x90: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xa0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xb0: 20 20 20 20 20 20 1b 5b 32 3b 31 48 75 6e 64 65        .[2;1Hunde
0xc0: 72 63 6c 6f 75 64 2d 75 6e 64 65 72 63 6c 6f 75  rcloud-underclou
0xd0: 64 2d 37 33 34 76 71 78 36 74 7a 63 33 7a 20 6c  d-734vqx6tzc3z l
0xe0: 6f 67 69 6e 3a 20 5b 20 20 20 38 32 2e 32 37 37  ogin: [   82.277
0xf0: 33 33 30 5d 20 69 6e 69 74 3a 20 55 6e 61 62 6c  330] init: Unabl
Offset: 0x100
0x00: 65 20 74 6f 20 63 6f 6e 6e 65 63 74 1b 5b 33 3b  e to connect.[3;
0x10: 31 48 20 74 6f 20 74 68 65 20 44 2d 42 75 73 20  1H to the D-Bus 
0x20: 73 79 73 74 65 6d 20 62 75 73 3a 20 46 61 69 6c  system bus: Fail
0x30: 65 64 20 74 6f 20 63 6f 6e 6e 65 63 74 20 74 6f  ed to connect to
0x40: 20 73 6f 63 6b 65 74 20 2f 76 61 72 2f 72 75 6e   socket /var/run
0x50: 2f 64 62 75 73 2f 73 79 73 74 65 6d 5f 62 75 73  /dbus/system_bus
0x60: 5f 73 1b 5b 34 3b 31 48 6f 63 6b 65 74 3a 20 4e  _s.[4;1Hocket: N
0x70: 6f 20 73 75 63 68 20 66 69 6c 65 20 6f 72 20 64  o such file or d
0x80: 69 72 65 63 74 6f 72 79 20 20 20 20 20 20 20 20  irectory        
0x90: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xa0: 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20                  
0xb0: 20 20 20 20 20 20 20 20 1b 5b 35 3b 31 48 43 6c          .[5;1HCl
0xc0: 6f 75 64 2d 69 6e 69 74 20 76 2e 20 30 2e 37 2e  oud-init v. 0.7.
0xd0: 36 20 72 75 6e 6e 69 6e 67 20 27 6d 6f 64 75 6c  6 running 'modul
0xe0: 65 73 3a 66 69 6e 61 6c 27 20 61 74 20 57 65 64  es:final' at Wed
0xf0: 2c 20 32 32 20 4f 63 74 20 32 30 31 34 20 31 31  . 22 Oct 2014 11




