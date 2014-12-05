
SESSION_NAME="ILO_GEN9"
ILOS="10.3.247.116 10.3.247.117 10.3.247.118 10.3.247.119 10.3.247.120 10.3.247.121 10.3.247.122 10.3.247.123"
#ILOS="ig9_1 ig9_2 ig9_3 ig9_4 ig9_5 ig9_6 ig9_7 ig9_8"

ILO_USER=nfv

SSH_OPTS="-o MACS=hmac-sha1,hmac-md5 -i /home/mjb/.ssh/ILO_dsa -o StrictHostKeyChecking=no -o ServerAliveInterval=60"

echo "Old sessions:"
tmux ls

echo "Killing $SESSION_NAME sessions:"
tmux kill-session -t $SESSION_NAME

echo "Old sessions:"
tmux ls

echo
echo "Creating new-session $SESSION_NAME"
tmux new-session -s $SESSION_NAME -d 'bash'

DATETIME=$(date +%Y-%m-%d-%Hh%Mm%S)
DIR=/home/mjb/ILO/${DATETIME}_${SESSION_NAME}.logs

[ ! -d $DIR ] && mkdir -p $DIR

echo
for ILO in $ILOS;do
    #tmux new-window -t $SESSION_NAME -d 'echo $ILO |& cat; bash'
    WINDOW_NAME=${ILO##*.}
    WINDOW_NAME=${WINDOW_NAME##*_}
    echo $WINDOW_NAME
    #tmux new-window -t ${SESSION_NAME}:${WINDOW_NAME} -d 'echo $ILO |& cat; bash'
    tmux new-window -t ${SESSION_NAME}:${WINDOW_NAME} -d "while true;do ssh $SSH_OPTS ${ILO_USER}@${ILO} textcons |& stdbuf -oL tee -a $DIR/ILO.log.${ILO}.raw; done"
done

#tmux new-window -t ILO_GEN9 -d 'bash'
#tmux new-window -t ILO_GEN9 -d 'bash'
#tmux new-window -t ILO_GEN9 -d 'bash'
echo
echo "New sessions:"
tmux ls

