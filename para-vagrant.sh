#!/bin/sh

# concurrency is hard, let's have a beer

# any valid parallel argument will work here, such as -P x.
MAX_PROCS="--use-cpus-instead-of-cores"

parallel_provision() {
    while read box; do
        echo $box
	 done | parallel $MAX_PROCS -I"BOX" -q \
	 	sh -c 'LOGFILE="logs/BOX.out.txt" ;									\
	 			printf  "[BOX] Provisioning. Log: $LOGFILE, Result: " ;		\
	 			vagrant provision BOX >$LOGFILE 2>&1 ; 				\
	 	        RETVAL=$? ; 											\
	 			if [ $RETVAL -gt 0 ]; then								\
	 				echo " FAILURE";									\
	 				tail -12 $LOGFILE | sed -e "s/^/[BOX]  /g";		\
	 				echo "[BOX] ---------------------------------------------------------------------------";	\
	 				echo "FAILURE ec=$RETVAL" >>$LOGFILE;			\
	 			else													\
	 				echo " SUCCESS";   									\
	 				tail -5 $LOGFILE | sed -e "s/^/[BOX]  /g";       \
	 				echo "[BOX] ---------------------------------------------------------------------------";	\
	 				echo "SUCCESS" >>$LOGFILE;						\
	 			fi;														\
	 			exit $RETVAL'

	failures=$(egrep  '^FAILURE' logs/*.out.txt | sed -e 's/^logs\///' -e 's/\.out\.txt:.*//' -e 's/^/  /')
	successes=$(egrep '^SUCCESS' logs/*.out.txt | sed -e 's/^logs\///' -e 's/\.out\.txt:.*//' -e 's/^/  /')

	echo '-------------------- Results --------------------------'
	echo
	echo "Failures: `echo "$failures" | wc -l`"
	echo '------------------'
	echo "$failures"
	echo
	echo "Successes: `echo "$successes" | wc -l`"
	echo '------------------'
	echo "$successes"
}

## -- main -- ##

# cleanup old logs
mkdir logs >/dev/null 2>&1 
rm -f logs/*.out.txt

# start boxes sequentially to avoid vbox explosions
echo ' ==> Calling "vagrant up" to boot the boxes...'
vagrant up --no-provision

# but run provision tasks in parallel
echo ' ==> Beginning parallel testing...'
cat <<EOF | parallel_provision
centos_6_64
centos_6_32
ubuntu_1004_32
ubuntu_1004_64
ubuntu_1104_32
ubuntu_1104_64
ubuntu_1110_32
ubuntu_1110_64
debian_6_32
debian_6_64
centos_5_64
centos_5_32
EOF
