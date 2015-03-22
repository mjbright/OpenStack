

function yesno
{
    resp=""
    default=""
    [ ! -z "$2" ] && default="$2"

    while [ 1 ]; do
        if [ ! -z "$default" ];then
            echo -n "$1 [yYnNqQ] [$default]:"
            read resp
            [ -z "$resp" ] && resp="$default"
        else
            echo -n "$1 [yYnNqQ]:"
            read resp
        fi
        [ \( "$resp" = "q" \) -o \( "$resp" = "Q" \) ] && exit 0
        [ \( "$resp" = "y" \) -o \( "$resp" = "Y" \) ] && return 1
        [ \( "$resp" = "n" \) -o \( "$resp" = "N" \) ] && return 0
    done
}

IFS=$'\n'
VMS=( $( nova list ) )

VMIDs=""
VMNAMEs=""

for VMline in ${VMS[@]}; do
    ## echo $VMline;
    IFS=' ';
    FIELDS=( $VMline );
    VMID="${FIELDS[1]}";
    VMNAME="${FIELDS[3]}";
    ## echo "VMID=$VMID"
    ## echo "VMNAME=$VMNAME"
    if [ "$VMID" = "ID" ];then
        continue
    fi

    VMIDs+=" ${VMID}"
    VMNAMEs+=" ${VMNAME}"
done

yesno "Delete VMs[$VMNAMEs]?" || {
    echo "nova delete $VMIDs";
    nova delete $VMIDs;
}
#echo "nova delete $VMIDs"
#echo "nova delete $VMNAMEs"

exit 0

  192  vi test_qn14.cpp 
  193  ./build_debug.sh test_qn14.cpp 
  194  vi test_qn14.cpp 
  195  ./build_debug.sh test_qn14.cpp 
  196  vi test_qn14.cpp 
  197  ./build_debug.sh test_qn14.cpp 
  198  vi test_qn14.cpp 
  199  ./build_debug.sh test_qn14.cpp 
  200  vi test_qn14.cpp 
  201  ./build_debug.sh test_qn14.cpp 
  202  vi test_qn14.cpp 
  203  ./build_debug.sh test_qn14.cpp 
  204  vi test_qn14.cpp 
  205  ./build_debug.sh test_qn14.cpp 
  206  vi test_qn14.cpp 
  207  ./build_debug.sh test_qn14.cpp 
  208  vi test_qn16.cpp
  209  ./build_debug.sh test_qn16.cpp 
  210  vi test_qn16.cpp
  211  ./build_debug.sh test_qn16.cpp 
  212  vi test_qn16.cpp
  213  ./build_debug.sh test_qn16.cpp 
  214  vi test_qn16.cpp
  215  ./build_debug.sh test_qn16.cpp 
  216  vi test_qn16.cpp
  217  ./build_debug.sh test_qn16.cpp 
  218  vi test_qn16.cpp
  219  ./build_debug.sh test_qn16.cpp 
  220  vi test_qn16.cpp
  221  vi test_qn16.cpp
  222  vi test_qn16.cpp
  223  ./build_debug.sh test_qn16.cpp 
  224  vi test_qn16.cpp
  225  ./build_debug.sh test_qn16.cpp 
  226  vi test_qn16.cpp
  227  ./build_debug.sh test_qn16.cpp 
  228  ll
  229  more build_debug.sh 
  230  vi build_debug.sh 
  231  ./build_debug.sh X
  232  vi build_debug.sh 
  233  ./build_debug.sh X
  234  vi build_debug.sh 
  235  ./build_debug.sh 
  236  ./build_debug.sh test_qn11.cpp 
  237  ./build_debug.sh test_qn9.*
  238  exp .
  239  df
  240  df
  241  ll /cygdrive/f/
  242  df
  243  ll /e/Education/Video/Editors/MasteringVim-with-DamianConway
  244  rsync -av --progress /e/Education/Video/Editors/MasteringVim-with-DamianConway /cygdrive/f/
  245  tv off
  246  which tv
  247  alias tv
  248  vi ~/z/bin/Deployed/freeboxremote
  249  vi ~/.freeboxremote 
  250  tv on
  251  tv on
  252  ll ~/z/www/mjbright.github.io/Pygre/images/
  253  exp ~/z/www/mjbright.github.io/Pygre/images/
  254  perl6 -e '"say hello".say'
  255  time perl6 -e '"say hello".say'
  256  time perl6 -e '"say hello".say'
  257  cd /d/src/git/
  258  git clone https://github.com/docker/docker
  259  find docker/ | wc -l
  260  find docker/ -type f | wc -l
  261  find docker/ -type f  | grep -v .git | wc -l
  262  ll docker/
  263  find docker/* -type f  | wc -l
  264  find docker/* -iname '*.go'
  265  find docker/* -iname '*.go' | wc -l
  266  ll docker/
  267  ll docker/utils/
  268  ll docker/utils/utils.go 
  269  more docker/utils/utils.go 
  270  #more docker/utils/utils.go 
  271  echo "#ffff00" | perl6 -ne '.comb(/\w\w/).map({:16($_)}).say'
  272  ipconfig
  273  exp /e/ExamsPrepa/CloudStack/Book_OReilly_Free_60-recipes-for-apache-cloudstack.pdf 
  274  ll /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 
  275  ll /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 
  276  ll /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 
  277  ssh b10cpq
  278  ssh seed9
  279  locate -i dvd | grep -i dropbox
  280  locate -i dvd | grep -i dropbox | grep -v OLD
  281  locate -i dvd | grep -i dropbox | grep -v OLD | grep -v \win32
  282  ll /d/z/
  283  ll /d/z/Config/
  284  locate -i dvd | grep -i dropbox | grep -v OLD | grep -v \win32
  285  ll /d/z/Education/HP/RedHat_GlusterFS/
  286  #locate -i dvd | grep -i dropbox | grep -v OLD | grep -v \win32
  287  ll /d/z/ArchiveIndex
  288  ll /d/z/ArchiveIndex/
  289  find /d/z/ArchiveIndex/
  290  find /d/z/ArchiveIndex/ -name '*DVD*'
  291  ll /d/z/ArchiveIndex/Catalog/DVD_Profiler/
  292  grep -i temoin /d/z/ArchiveIndex/Catalog/DVD_Profiler/
  293  grep -ir temoin /d/z/ArchiveIndex/Catalog/DVD_Profiler/
  294  grep -ir denzel /d/z/ArchiveIndex/Catalog/DVD_Profiler/
  295  vim /d/z/ArchiveIndex/Catalog/DVD_Profiler/EliteBook.Collection.xml 
  296  a profiler
  297  ll -tr /e/HELION/
  298  ll -tr /e/HELION/v1.0.1/
  299  rsync -av --progress /e/HELION/v1.0.1 b10cpq:HP_Helion*/
  300  cd /d/src/git/
  301  mkdir hewlettpackard
  302  cd hewlettpackard
  303  #git clone 
  304  cd ../
  305  mkdir HP
  306  rmdir hewlettpackard/
  307  cd HP/
  308  mkdir HP-OneView
  309  cd HP-OneView
  310  git clone https://github.com/hewlettpackard .
  311  #echo "git clone https://github.com/hewlettpa
  312  cd ../
  313  history > clone.sh
  314  vi clone.sh 
  315  chmod +x clone.sh 
  316  ll
  317  a packtpub
  318  ll
  319  ./clone.sh 
  320  ll
  321  du -s *
  322  vi clone.sh 
  323  ./clone.sh 
  324  vi clone.sh 
  325  ./clone.sh 
  326  vi clone.sh 
  327  ./clone.sh 
  328  vi clone.sh 
  329  ./clone.sh 
  330  echo "#ffff00" | perl6 -ne '.comb(/\w\w/).map({:16($_)}).say'
  331  exp /d/z/Mobile/Books/New
  332  exp /d/z/Mobile/Books/
  333  ssh -i ~/.ssh/compute1.rsa 10.3.160.28 id
  334  ssh -i ~/.ssh/compute1.rsa root@10.3.160.28 id
  335  ssh -i ~/.ssh/compute1.rsa.pub root@10.3.160.28 id
  336  ssh -i ~/.ssh/compute1.rsa.pub root@10.3.160.28 id
  337  ssh -i ~/.ssh/compute1.rsa root@10.3.160.28 id
  338  ssh -i ~/.ssh/compute2.rsa root@10.3.160.29 id
  339  rsync -anv --progress /e/Education/ mjb@10.3.3.117:Education/ | grep -v /$
  340  rsync -anv --progress mjb@10.3.3.117:Education/ /e/Education/ | grep -v /$
  341  rsync -av --progress mjb@10.3.3.117:Education/ /e/Education/ | grep -v /$
  342  rsync -av --progress mjb@10.3.3.117:Education/ /e/Education/ | grep -v /$
  343  syncToTablet.sh
  344  #syncToTablet.sh 
  345  grep iconia /etc/hosts 
  346  grep iconia /etc/hosts 
  347  more /d/.ssh/config 
  348  vim /d/.ssh/config 
  349  ssh root@10.3.134.13:2222
  350  ssh -p 2222 root@10.3.134.13
  351  ll /d/.ssh
  352  ll /d/.ssh/
  353  locate cpq | grep rsa
  354  locate cpq | grep pub
  355  locate -i cpq
  356  ssh -t ~/.ssh/id_rsa -p 2222 root@10.3.134.13
  357  ssh -i ~/.ssh/id_rsa -p 2222 root@10.3.134.13
  358  ssh -i ~/.ssh/id_dsa -p 2222 root@10.3.134.13
  359  ll /d/.ssh/id_rsa*
  360  ll /d/.ssh/id_*
  361  ll /d/.ssh
  362  ll /d/.ssh/
  363  ssh -i ~/.ssh/id_rsa -p 2222 root@10.3.134.13
  364  ssh -vv -i ~/.ssh/id_rsa -p 2222 root@10.3.134.13
  365  ssh -vv -i ~/.ssh/id_rsa.pub -p 2222 root@10.3.134.13
  366  ssh -vv -i ~/.ssh/id_rsa -p 2222 root@10.3.134.13
  367  ssh h1c1
  368  ssh -vv -i ~/.ssh/compute2.rsa -p 2222 root@10.3.160.29
  369  ssh -vv -i ~/.ssh/compute2.rsa root@10.3.160.29
  370  ssh -vv -i ~/.ssh/compute2.rsa heat-admin@10.3.160.29
  371  ssh -vv -i ~/.ssh/compute1.rsa heat-admin@10.3.160.28
  372  ssh -vv -i ~/.ssh/compute3.rsa heat-admin@10.3.160.30
  373  ssh -vv -i ~/.ssh/compute3.rsa heat-admin@10.3.160.30
  374  ssh -vv -i ~/.ssh/compute2.rsa heat-admin@10.3.160.29
  375  exp /c/rakudo/
  376  a canvas
  377  /c/rakudo/bin/perl6.bat 
  378  more /c/rakudo/bin/perl6.bat 
  379  /c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm
  380  /c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm -e "'Hello World'.say"
  381  time /c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm -e "'Hello World'.say"
  382  time /c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm -e "'Hello World'.say"
  383  time /c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm -e "'Hello World'.say"
  384  alias perl6='/c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm' 
  385  perl6 -e "'hello world'.say"
  386  #alias perl6='/c/rakudo/bin/moar.exe --libpath="c:/rakudo/languages/nqp/lib" --libpath="c:/rakudo/languages/perl6/lib" --libpath="c:/rakudo/languages/perl6/runtime" c:/rakudo/languages/perl6/runtime/perl6.moarvm' 
  387  history | grep alias >> H
  388  ll .bash*
  389  vi .bashrc 
  390  vi .bashrc 
  391  unalias perl6
  392  perl6 -e "'hello world'.say"
  393  . .bashrc 
  394  perl6 -e "'hello world'.say"
  395  ls /cygdrive/e/playlist/OUVERTUREDuBal/
  396  cp -a /cygdrive/e/playlist/OUVERTUREDuBal/*.mp3 /cygdrive/f/OUVERTUREDuBal
  397  mkdir /cygdrive/f/OUVERTUREDuBal
  398  mkdir /cygdrive/f/Pictures
  399  cp -a /cygdrive/e/playlist/OUVERTUREDuBal/*.mp3 /cygdrive/f/OUVERTUREDuBal
  400  a helion
  401  a helion
  402  ssh -p 2222 root@192.168.0.12
  403  ssh -p 2222 root@192.168.0.12
  404  ssh -p 2222 root@192.168.0.12
  405  #ssh -vv -i ~/.ssh/id_rsa.pub -p 2222 root@10.3.134.13
  406  cat ~/.ssh/id_rsa.pub 
  407  cp ~/.ssh/id_rsa.pub  ~/z/Config/elite.pub
  408  ssh -p 2222 root@192.168.0.23
  409  mcd
  410  gvim FR_EU_Axa_CA.mon
  411  m
  412  gvim FR_EU_Oney-VISA.mon
  413  a lonely
  414  vi /d/z/data/calls/2014.txt 
  415  gvim FR_EU_Oney-VISA.mon
  416  cd /c/Users/mjbright/Downloads/
  417  ll -tr
  418  rename 's/chile-easter-island/Book_LonelyPlanet_Chile_EasterIsland/' chile-easter-island-9*
  419  rename 's/south-america-on-a-shoestring/Book_LonelyPlanet_SouthAmerica_OnAShoestring/' south-america-*
  420  ll -tr
  421  rename 's/south-america-12/Book_LonelyPlanet_SouthAmerica_OnAShoestring/' south-america-*
  422  ll -tr
  423  mv Book_LonelyPlanet_* /d/z/Mobile/New/
  424  ll -tr
  425  cd -
  426  tail -100 FR_EU_Oney-VISA.mon
  427  cd -
  428  ll -tr
  429  mv Comptes.xlsx $OLDPWD/
  430  cd -
  431  ll -tr
  432  mv Comptes.xlsx Paulina_Comptes_Travaux.xlsx
  433  ll -tr
  434  cd
  435  ssh mjb@10.3.3.117 ls -altr
  436  ssh mjb@10.3.3.117
  437  a sncf
  438  mcd
  439  gvim FR_EU_Axa_CA.mon
  440  gvim FR_EU_Oney-VISA.mon
  441  m
  442  vim FR_EU_Axa_CA.mon
  443  vim FR_EU_LaPoste_LivretA_SA.mon
  444  grep LivretA FR_EU_Axa_CA.mon
  445  grep LivretA FR_EU_Axa_CA.mon | grep 650
  446  vim FR_EU_LaPoste_LivretA_SA.mon
  447  vim FR_EU_Axa_CA.mon
  448  m
  449  grep iconia /etc/hosts 
  450  #syncToTablet.sh -rsync /e/FISHCALLEDWANDA/FILM_AFishCalledWanda.hbq 
  451  ll -rt /e/
  452  ll -rt /e/FISHCALLEDWANDA/
  453  ll -rt /e/FISHCALLEDWANDA/VIDEO_TS/
  454  ll -rt /e/Media.New
  455  ll -rt /e/Media.New/DVD/
  456  mv /c/Progs/Media/Handbrake/FILM_AFishCalledWanda.mp4 /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4
  457  #ll -rt /e/Media.New
  458  syncToTablet.sh -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4
  459  syncToTablet.sh -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/
  460  vi ~/z/bin/Deployed/syncToTablet.sh
  461  pingiconia
  462  ping iconia
  463  ssh root@iconia
  464  vi /d/.ssh/config 
  465  ping iconia
  466  ssh root@iconia
  467  ssh root@iconia
  468  syncToTablet.sh -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/
  469  syncToTablet.sh -go -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/
  470  vi ~/z/bin/Deployed/syncToTablet.sh
  471  syncToTablet.sh -p -go -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/
  472  syncToTablet.sh -p -go -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/Movies/
  473  vi ~/z/bin/Deployed/syncToTablet.sh
  474  syncToTablet.sh -p -go -rsync /e/Media.New/DVD/FILM_DVD_AFishCalledWanda.mp4 /storage/sdcard0/Movies/
  475  ping 192.168.0.17
  476  ssh root@192.168.0.17
  477  ssh seedhost
  478  ssh seedhost
  479  ll /d/z/bin/HP/2014-B10/
  480  ll /d/z/bin/HP/2014-B10/Helion/
  481  ll /d/z/bin/HP/2014-B10/Helion/2014-Oct-22-Jerome_Helion_Scripts/
  482  more /d/z/bin/HP/2014-B10/Helion/2014-Oct-22-Jerome_Helion_Scripts/baremetal.csv
  483  more /d/z/bin/HP/2014-B10/Helion/2014-Oct-22-Jerome_Helion_Scripts/env_vars
  484  exp /d/z/bin/HP/2014-B10/Helion/2014-Oct-22-Jerome_Helion_Scripts/env_vars
  485  vi /d/z/data/calls/2015.txt 
  486  more /d/z/bin/HP/2014-B10/Helion/2014-Dec-PoC1-Gen9/kvm-custom-ips.json 
  487  exp /d/z/bin/HP/2014-B10/Helion/2014-Dec-PoC1-Gen9/kvm-custom-ips.json 
  488  ssh seedpoc1
  489  cd /d/z/www/mjbright.github.io/Pygre/
  490  locate -i markdown2.py
  491  cp /d/src/git/python-markdown2/lib/markdown2.py  .
  492  ll /d/src/git/python-markdown2/*/markdown2.py  markdown2.py 
  493  #ll /d/src/git/python-markdown2/*/markdown2.py  markdown2.py 
  494  ll /d/z/CACHED/WHATIF/markdown2.py 
  495  ll /c/Progs/Anaconda/envs/py3k/Lib/site-packages/markdown2.py 
  496  ll /c/Progs/Anaconda/envs/py3k/Scripts/markdown2.py 
  497  cp /c/Progs/Anaconda/envs/py3k/Scripts/markdown2.py  .
  498  ll
  499  git mv ProposingPresentations.html Contributions.html
  500  markdown2.py 
  501  cd
  502  ll /e/Adobe.Captivate/
  503  ll /e/Adobe.Captivate/
  504  ll -tr /e/Adobe.Captivate/
  505  #ll -tr /c/Progs/Ad
  506  ll /c/Program\ Files/Adobe/
  507  ll /c/Program\ Files/Adobe/Adobe\ Captivate\ 8\ x64/
  508  ll -tr /c/Program\ Files/Adobe/Adobe\ Captivate\ 8\ x64/
  509  du -s /c/Program\ Files/Adobe/Adobe\ Captivate\ 8\ x64/
  510  du -s /e/Adobe.Captivate/*
  511  du -s /e/Adobe.Captivate/Cached.Projects/*
  512  ll -rt /e/Adobe.Captivate/Cached.Projects/
  513  ll -tr /e/Education/HP/Webinars/2015-Mar-19_PrivateDemo_CMS_WebRTC_FredHuve/
  514  ll -tr /e/Adobe.Captivate/
  515  ll -tr /e/Adobe.Captivate/2015-Mar-19_PrivateDemo_CMS_WebRTC.cpvc 
  516  ll -rt /e/Adobe.Captivate/Cached.Projects/
  517  du -s /e/Adobe.Captivate/Cached.Projects/ /e/Adobe.Captivate/2015-Mar-19_PrivateDemo_CMS_WebRTC.cpvc 
  518  cd ~/z/bin/HP/2014-B10/Helion/MikeClient_Scripts
  519  ll
  520  #bash LAUNCHER.sh -v TEST1 -cirros
  521  #nova list
  522  . demo8.rc 
  523  nova list
  524  nova list
  525  neutron net-list
  526  neutron net-list | grep TEST
  527  neutron subnet-list | grep TEST
  528  bash LAUNCHER.sh -v TEST1 -cirros
  529  bash LAUNCHER.sh -v -TEST1 -cirros
  530  #vi /d/z/data/calls/2015.txt 
  531  vi LAUNCHER.sh
  532  vi LAUNCHER.sh
  533  bash LAUNCHER.sh -v -TEST1 -cirros
  534  vi LAUNCHER.sh
  535  bash LAUNCHER.sh -v -TEST1 -cirros
  536  vi LAUNCHER.sh
  537  bash -x LAUNCHER.sh -v -TEST1 -cirros
  538  vi LAUNCHER.sh
  539  #cp /c/Progs/Anaconda/envs/py3k/Scripts/markdown2.py  .
  540  cp LAUNCHER.sh LAUNCHER.sh.3
  541  bash LAUNCHER.sh -v -TEST1 -cirros
  542  neutron subnet-list | grep 192.168
  543  vi LAUNCHER.sh
  544  vi LAUNCHER.sh
  545  bash LAUNCHER.sh -v -TEST1 -cirros
  546  vi LAUNCHER.sh
  547  bash LAUNCHER.sh -v -TEST1 -cirros
  548  neutron subnet-list
  549  neutron subnet-list | grep TEST
  550  vi LAUNCHER.sh
  551  bash LAUNCHER.sh -v -TEST1 -cirros
  552  nova list
  553  vi LAUNCHER.sh
  554  nova delete cirros cirros_20150319_202315
  555  #bash LAUNCHER.sh -v -TEST1 -cirros
  556  nova list
  557  bash LAUNCHER.sh -v -TEST1 -cirros
  558  vi LAUNCHER.sh
  559  seq 1 4
  560  bash LAUNCHER.sh -v -TEST1 -cirros
  561  nova list
  562  nova delete cirros cirros_20150319_202916
  563  vi LAUNCHER.sh
  564  echo A B C | wc -l
  565  echo A B C | wc -c
  566  echo A B C | wc -w
  567  vi LAUNCHER.sh
  568  bash LAUNCHER.sh
  569  bash LAUNCHER.sh -cirros
  570  l
  571  ll
  572  cp LAUNCHER.sh LAUNCHER.sh.3
  573  ll
  574  nova list
  575  nova delete cirros coreos
  576  nova list
  577  #ll /d/.ssh/
  578  ll /d/z/Dropbox/
  579  ll -tr /d/z/Dropbox/
  580  ll -tr /d/z/Dropbox/
  581  ll -tr /d/z/Dropbox/
  582  ll -tr /d/z/Dropbox/
  583  ll -tr /d/z/Dropbox/
  584  ll -tr /d/z/Dropbox/
  585  mv /d/z/Dropbox/coreos_rsa* /d/.ssh/
  586  ll /d/.ssh/coreos_*
  587  chmod 400 /d/.ssh/coreos_*
  588  ll /d/.ssh/coreos_*
  589  nova list
  590  #./LAU
  591  vi LAUNCHER.sh
  592  vi LAUNCHER.sh
  593  vi LAUNCHER.sh
  594  bash LAUNCHER.sh
  595  nova list
  596  vi LAUNCHER.sh
  597  bash LAUNCHER.sh
  598  vi LAUNCHER.sh
  599  nova floating-ip-list
  600  nova --version
  601  nova floating-ip-list
  602  ll TEST.sh 
  603  bash TEST.sh 
  604  cksum TEST.sh 
  605  bash TEST.sh 
  606  #nova floating-ip-list
  607  vi TEST.sh 
  608  bash TEST.sh 
  609  cksum TEST.sh 
  610  vi TEST.sh 
  611  bash TEST.sh 
  612  vi TEST.sh 
  613  bash TEST.sh 
  614  vi TEST.sh 
  615  bash TEST.sh 
  616  vi TEST.sh 
  617  bash TEST.sh 
  618  vi TEST.sh 
  619  bash TEST.sh 
  620  vi TEST.sh 
  621  bash TEST.sh 
  622  vi TEST.sh 
  623  bash TEST.sh 
  624  vi TEST.sh 
  625  bash TEST.sh 
  626  vi TEST.sh 
  627  bash TEST.sh 
  628  vi TEST.sh 
  629  bash TEST.sh 
  630  vi TEST.sh 
  631  bash TEST.sh 
  632  vi TEST.sh 
  633  bash TEST.sh 
  634  cksum TEST.sh 
  635  vi TEST.sh 
  636  cksum TEST.sh 
  637  cksum TEST.sh 
  638  cksum TEST.sh 
  639  bash TEST.sh 
  640  vi TEST.sh 
  641  bash TEST.sh 
  642  vi TEST.sh 
  643  cksum TEST.sh 
  644  bash TEST.sh 
  645  vi TEST.sh 
  646  bash TEST.sh 
  647  vi TEST.sh 
  648  bash TEST.sh 
  649  vi TEST.sh 
  650  bash TEST.sh 
  651  vi TEST.sh 
  652  cksum TEST.sh 
  653  bash TEST.sh 
  654  vi TEST.sh 
  655  bash TEST.sh 
  656  vi TEST.sh 
  657  bash TEST.sh 
  658  cksum TEST.sh 
  659  bash TEST.sh 
  660  vi TEST.sh 
  661  vi LAUNCHER.sh
  662  vi TEST.sh 
  663  vi LAUNCHER.sh
  664  cksum LAUNCHER.sh
  665  bash LAUNCHER.sh -cirros
  666  vi LAUNCHER.sh
  667  bash -x LAUNCHER.sh -cirros
  668  grep id /tmp/imageBoot.26032 
  669  vi LAUNCHER.sh
  670  bash -x LAUNCHER.sh -cirros
  671  vi LAUNCHER.sh
  672  #bash -x LAUNCHER.sh -cirros
  673  nova list
  674  #nova delete cirros cirros_20150320_153839
  675  #nova list | 
  676  VMS=( $( nova list ) )
  677  for VMline in ${VMS[@]}; do echo $VLline; done
  678  for VMline in ${VMS[@]}; do echo $VLMline; done
  679  for VMline in ${VMS[@]}; do echo $VMline; done
  680  #for VMline in ${VMS[@]}; do echo $VMline; done
  681  #for VMline in ${VMS[@]}; do echo $VLline; done
  685  for VMline in ${VMS[@]}; do IFS=' '; FIELDS=( $VMline); for F in ${FIELDS[@]}; do echo F=$F; done; done
  686  for VMline in ${VMS[@]}; do IFS=' '; FIELDS=( $VMline); echo $VMline; done
  687  for VMline in ${VMS[@]}; do IFS=' '; FIELDS=( $VMline); echo ${VMline[@]}; done
  688  for VMline in ${VMS[@]}; do IFS=' '; FIELDS=( $VMline); echo ${VMline[@]}; done
  689  for VMline in ${VMS[@]}; do IFS=' '; FIELDS=( $VMline); echo $VMline; done
  690  history
  691  history > nova_delete_all.sh


