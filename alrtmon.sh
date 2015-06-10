#!/bin/bash
expdate=`date '+%d_%m_%Y_%H_%M_%S'`

> /tmp/errlinenum.txt
> /tmp/alrterr.txt

export alrtlog=/orabin/app/oracle/diag/rdbms/dbname/DBNAME/trace/alert_DBNAME.log

wc -l $alrtlog > /tmp/alrtmon.txt
cntlastlin=`awk '{print $1}' /tmp/alrtmon.txt`
echo $cntlastlin >> /tmp/alrtmoncount.txt
cnt2lin=`tail -2 /tmp/alrtmoncount.txt | head -1`

if [[ "$cntlastlin" -eq "$cnt2lin" ]]
then 
	echo "Condition of equality met"	
	echo $cntlastlin and $cnt2lin
	exit 0
elif [[ "$cntlastlin" -gt "$cnt2lin" ]]
then 
	tail -n +$cnt2lin $alrtlog > /tmp/alrtmon.txt

	while read inputline
        	do
                	echo $inputline > test1.txt
                	count=$((count+1))
			input=`cat test1.txt`
			input1=`cat test1.txt |awk '{print $1}'`
			input2=`echo $input1 | cut -b -4`
			if [[ $input1 = "ORA-12012:" || $input1 = "ORA-01555" || $input1 = "ORA-20001:" || $input1 = "ORA-06512:" || $input1 = "ORA-00604:" || $input1 = "ORA-01461:" || $input1 = "ORA-00060:" ]]
			then
                        	echo "Error can be ignored as it is caused by an SQL statement or a JOB or a deadlock"
			else 
				if [[ $input2 = ORA- ]]
				then
					echo "Error at line number in errlinenum.txt "$count
					errlinenum=$count
					echo $errlinenum >> /tmp/errlinenum.txt
				else
                        		echo $input2 > /dev/null
				fi
			
			fi
	done < /tmp/alrtmon.txt

	#Check if file is empty or not
	if [ -s /tmp/errlinenum.txt ]
		then
			echo "Error in alertlog file at" $expdate
			
			while read inputline2
       			do
	                	sed -n "$inputline2"p /tmp/alrtmon.txt >> /tmp/alrterr.txt
			done < /tmp/errlinenum.txt
		
			#/usr/bin/perl /backup/dba/alert_monitor/alert_mail.sh	
		else
			echo "No error in alertlog file at" $expdate
	fi
elif [[ "$cntlastlin" -lt "$cnt2lin" ]]
then
	echo "Condition of less than met"
	echo $cntlastlin and $cnt2lin
	echo "Check and reset /tmp/alrtmoncount.txt"  
	exit 1
else
   echo "None of the condition met"
fi
