trap "" 1,2,3,15

#�ȴ�ʱ��
SLEEP_TIME=3
#Ԥ��ֵ
YJ_NUM=30
#�����ļ�
CFGFILE=PQ.list

Fun_PSR()
{
if [ $1 -eq 0 ]
then
	echo psr|tmadmin -r|grep $2|wc -l|sed 's/ //g'
else
	echo psr|tmadmin -r|grep $2|grep -v IDLE|wc -l|sed 's/ //g'
fi
}

while true
do
#��ǰʱ��
DT2=`date '+%Y-%m-%d %H:%M:%S'`
#��ǰ����
DT=`date '+%Y%m%d'`
#��־�ļ�
LOGFILE="/app/log/pq.$DT.txt"
#Ԥ���ļ�
YJFILE="/app/log/PQ.$DT.txt"

echo "===================================������м��̨=================================" >>${LOGFILE}
#��������
echo pq | tmadmin | sort -n -k5  |grep -v GW | tail -n 30 >>${LOGFILE}
#����BUSYֵ
PCLT=`echo pclt| tmadmin | grep BUSY|wc -l|sed 's/ //g'` 
#echo "  "  >>${LOGFILE}
#echo "  "  >>${LOGFILE}

echo "----------------------------->Date:$DT2<---------------------------" >>${LOGFILE}
for list in `cat $CFGFILE|grep -v "#"|grep -v "1"`
do 
	DT3=`date '+%H:%M:%S'`
	SERVER_NM=`echo $list|awk -F "|" '{print $1}'`
	SERVER_ID=`echo $list|awk -F "|" '{print $2}'`
	echo $SERVER_NM
	echo $SERVER_ID
		
	SERVER_S=`Fun_PSR 0 "$SERVER_ID"` 
 	SERVER_C=`Fun_PSR 1 "$SERVER_ID"`
	SERVER_P=`echo "scale=2;a=$SERVER_C;b=$SERVER_S;(a/b)*100"|bc`
	#printf "�� %s ����<%s> �ܷ�����[%s],	��ǰ����[%s],	ռ����[%s%%]\n" "$SERVER_NM" "$SERVER_ID" "$SERVER_S" "$SERVER_C" "$SERVER_P" >>${LOGFILE}
	printf "�� %s ��%s��<%s> �ܷ�����[%s],	��ǰ����[%s],	ռ����[%s%%]\n" "$SERVER_NM" "$DT3" "$SERVER_ID" "$SERVER_S" "$SERVER_C" "$SERVER_P" >>${LOGFILE}


if [ $SERVER_P -gt $YJ_NUM ]
then
	#echo "----------------------------->Date:$DT2<----------------------------" >>${YJFILE}
	#printf "�� %s ����<%s> �ܷ�����[%s],	��ǰ����[%s],	ռ����[%s%%]\n" "$SERVER_NM" "$SERVER_ID" "$SERVER_S" "$SERVER_C" "$SERVER_P" >>${YJFILE}
	printf "�� %s ��%s��<%s> �ܷ�����[%s],    ��ǰ����[%s],   ռ����[%s%%]\n" "$SERVER_NM" "$DT3" "$SERVER_ID" "$SERVER_S" "$SERVER_C" "$SERVER_P" >>${YJFILE}
        #printf "�� %s ��%s��<%s> �ܷ�����[%s],    ��ǰ����[%s],   ռ����[%s%%]\n" "$SERVER_NM" "$DT3" "$SERVER_ID" "$SERVER_S" "$SERVER_C" "$SERVER_P" > /home/view/logmonitor/log/app.txt
        #chmod 777 /home/view/logmonitor/log/app.txt
fi

done
echo "------------------------------------< BUSY:$PCLT >------------------------------------" >>${LOGFILE}
echo "" >>${LOGFILE}
echo "" >>${LOGFILE}

sleep $SLEEP_TIME
done
