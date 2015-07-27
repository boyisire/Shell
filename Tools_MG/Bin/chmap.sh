#!/bin/bash

DTS=`date +%s`
NUM2=`expr 16 \* 60 \* 60`
DTS2=`expr $DTS - $NUM2`
DTY=`date +"%Y%m%d"`
NUM=`expr $DTS2 / 24 / 60 / 60`
DAYNUM=`expr $NUM % 3`
#echo"$DAYNUM"

#LOCAL_DB="chmap/$BSW_USER"
LOCAL_DB="chmap/chmap@admas"
REMOTE_DB="chmap3/chmap3@admas"
#REMOTE_DB="chmap/$BSW2_USER"
LOCAL_SQL_1="SELECT t.paramvalue FROM cm_param t WHERE t.paramcode='CLEARDATE';"
LOCAL_SQL_2="select '�յ�����ʱ��[' || t.recv_date_time || ']', '	���п�ʼʱ��[' || t.change_date_time || ']', '	����ǰ��������[' || t.before_acc_date || ']', '	���ĺ���������[' || t.acc_date || ']' from Ol_Daychange t WHERE t.recv_date_time>(select to_char ((sysdate-1),'YYYYmmdd')||'000000' from dual);"
LOCAL_SQL_16="select count(*) from Ol_Daychange t WHERE t.recv_date_time>(select to_char ((sysdate-1),'YYYYmmdd')||'000000' from dual);"

#---------------------------------------------------------------------------------------------------------
lsh()
{
DATE="$ZQ"
TIME="$TQ"
LSH="$SEQ"

echo "��ʼ���� [$ZQ] [$TQ] [$SEQ] [$PID]"

for i in `ls -1 $HOME/log/$PID*.debug`
do
        PID=`echo $i | awk -F "\." '{print $1}'`
#echo "PID=$PID"
        ls -arlt $PID* | grep -i "$DATE" >$HOME/log/tmp1.txt
	linenum=`wc -l $HOME/log/tmp1.txt| awk '{print $1}'`
	if [ $linenum -eq 0 ]
	then
		continue
	fi	
        while read line
        do
#echo "��ǰ��Ϊ$line"
                #ȡ��ǰ�е��޸�ʱ��

                CURTIME=`echo $line | awk -F "\." '{print $NF}'`
                FILENAME=`echo $line | awk '{print $9}'`
#echo "[CURTIME=$CURTIME]"
#echo "[TIME=$TIME]"
                if [ "$CURTIME" == "debug" ]
                then
#echo "���ļ�[$FILENAME]�в��ҽ������"
                        break

                else
                        if [[ "$CURTIME" <  "$TIME" ]]
                        then
#echo "С��"
                                continue
                        else
#echo "[$CURTIME]>[$TIME]"
#echo "���� $FILENAME"
                                break
                        fi
                fi
        done <$HOME/log/tmp1.txt
        printf "."
#echo "LSH=[$LSH] FILENAME=[$FILENAME]"
        grep $LSH $FILENAME
        result=$?

        if [ $result -eq 0 ]
        then
                echo "���ļ�[    $FILENAME     ]�в��ҽ������"
                echo "�Ѿ��ҵ����˳�����"
         #       exit
        fi
done
grep $LSH $HOME/log/XML*

result=$?

        if [ $result -eq 0 ]
        then
                echo "�Ѿ��ҵ����˳�����"
         #       exit
        fi

}
#---------------------------------------------------------------------------------------------------------

FUN_QSRQ()
{
		 QSRQ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_1"`;
		 QSTZ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_2"`;
		 QSTZC=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_16"`;
		 QSTZCT=`echo "$QSTZC" | sed 's/ //g'`;
		 echo "#####ע������û���յ�����֪ͨ����Ӧ�����ڶԲ���#####";
		 echo "�����������ڣ�$QSRQ";
		 if [ "$QSTZCT" -eq "0" ]
		 then 
		 	echo "���棺����û���յ�����֪ͨ�����飡"
		 fi
		 echo "$QSTZ";
		 echo "--------------------------------------------------------------------------------------------------------";
		 grep load $HOME/log/Day* | tail -n 2 | awk -F "|" '{print $1 $2 $6}';
		 echo "--------------------------------------------------------------------------------------------------------";	
}

FUN_PSR()
{
		 echo "psr" | tmadmin -r | sort -n -k6| tail -n 100;
		 echo "---------      ----------  --------      -- ------ --------- ---------------";
}

FUN_PSC()
{
		 echo "psc" | tmadmin -r | sort -n -k7| tail -n 100;
		 echo "---------      ----------  --------      -- ------ --------- ---------------";
}

FUN_PQ()
{
		 echo "pq" | tmadmin -r| grep -v GWADM|grep -v GWTDOMAIN | sort -n -k6 | tail -n 20;
		 echo "---------      ----------  --------      -- ------ --------- ---------------";
}

FUN_LS()
{
		 echo "please input seqno��\c"
		 read SEQ
		 echo "please input date[Ĭ��$DTY]:\c"
		 read NEWDTY
		 
		 if [ "A$NEWDTY" != "A" ]
		 then
				NEWDAYNUM=`CONNECT_SQL "$LOCAL_DB" "select mod(to_date('$NEWDTY','YYYYMMDD')-to_date('19700101','YYYYMMDD')-1,3) from dual;"`
		 		
		 else
		 	  NEWDAYNUM=$DAYNUM
		 	  NEWDTY=$DTY
		 fi
		 
     NEWDAYNUM=`echo $NEWDAYNUM | sed -e 's/ //g'`

		 CURRENT_DB=$LOCAL_DB
		 LOCAL_SQL_3="select '��������[' || t.transdate || ']', ' ����ʱ��[' || substr(LOCALDATETIME,9,6) ||  ']', ' ���׻���[' || t.transdept || ']', ' ��Ʒ����[' || t.sendprodcode || ']',  ' ��־IP[' || t.logip || ']',' PID[' || t.pid || ']'
from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY' and rownum=1;"
		 echo "����[$DTY]����ˮ����[OL_TRANSDETAIL_$NEWDAYNUM],ע����ˮ�ķ�������!"

		 LSCX=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_3"`;
		 
if [ "A$LSCX" == "A" ]
then
		 LSCX=`CONNECT_SQL "$REMOTE_DB" "$LOCAL_SQL_3"`;
		 CURRENT_DB=$REMOTE_DB
fi
if [ "A$LSCX" == "A" ]
then
		 echo "δ�ҵ���ˮ��[$SEQ]��Ӧ��¼"
		 return
fi

		 echo "$LSCX";
		 
     echo "���ݿ��ѯ���Ϊ CONNECT_SQL \"$CURRENT_DB\" \"select transdate,substr(LOCALDATETIME,9,6),logip,pid  from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY'  and rownum=1 order by LOCALDATETIME desc;\""

		 RESULT=`CONNECT_SQL "$CURRENT_DB" "select transdate,'@',substr(LOCALDATETIME,9,6),'@',logip,'@',pid from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY'  and rownum=1 order by LOCALDATETIME desc ;"`
		 RQ=`echo "$RESULT" | awk -F "@" '{print $1}' |sed -e 's/ //g'`
		 TQ=`echo "$RESULT" | awk -F "@" '{print $2}'|sed -e 's/ //g'`		
		 IP=`echo "$RESULT" | awk -F "@" '{print $3}'|sed -e 's/ //g'`				 
		 PID=`echo "$RESULT" | awk -F "@" '{print $4}'|sed -e 's/ //g'|sed -e 's/	//g`				 
		echo "PID=[$PID]"
		 ZQ=`CONNECT_SQL "$CURRENT_DB" "select to_char(to_date('$RQ','YYYYMMDD'),'Mon ') || decode(to_char(to_date('$RQ','YYYYMMDD'),'DD'),'01',' 1','02',' 2','03',' 3','04',' 4','05',' 5','06',' 6','07',' 7','08',' 8','09',' 9',to_char(to_date('$RQ','YYYYMMDD'),'DD')) from dual;"`
echo "[$RQ][$TQ][$IP][$PID][$ZQ]"		 
		 HOSTNAME=`hostname`
		 GETIP=`grep $HOSTNAME /etc/hosts | awk '{print $1}'`

		 if [ $IP != $GETIP ]
		 then
				echo "���¼[$IP]��ѯָ�����̺�[$PID]��ˮ[$SEQ]"
				return
		 fi
#     TQ=`CONNECT_SQL "$CURRENT_DB" "select substr(LOCALDATETIME,9,6) from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY'  and rownum=1 order by LOCALDATETIME desc ;"`


		 lsh;
}

FUN_QX()
{
		 echo "�������Ա�ţ�\c"
     read GUIYUAN
     LOCAL_SQL_4="select '��Ա['||t.operno||']', ' ��ɫ['||t.rolenos||']',' ��������['||t.adddate||']',' �޸�����['||t.chdate||']' from ol_operrole t where t.operno = '$GUIYUAN' and t.sysno = '99200000000';";
     GYQX=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_4"`;
     echo "$GYQX"
     echo "�����뽻���룺\c"
     read JIAYM
     LOCAL_SQL_5="select t.ruleno from ol_ruletrans t where t.prodcode='$JIAYM' and sysno='99200000000';";
     JYMJ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_5"`;
     echo "˵����99�������λ�ǽ�ɫ���룬δλ1��ʾ����Ȩ�ޣ�2��ʾ��ȨȨ��"
     echo "$JYMJ"
}

FUN_HS()
{
		 echo "ECIF     ƽ����ʱ��"`grep ��ʱ $HOME/log/*.ECIF | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"�����룩"
		 echo "ZJQS     ƽ����ʱ��"`grep ��ʱ $HOME/log/*.ZJQS | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"�����룩"
		 echo "TOKEN    ƽ����ʱ��"`grep ��ʱ $HOME/log/*.TOKEN | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"�����룩"
		 echo "ZHIWEN   ƽ����ʱ��"`grep ��ʱ $HOME/log/*.ZHIWEN | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"�����룩"
		 echo "185   ƽ����ʱ��"`grep ��ʱ $HOME/log/*.185 | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"�����룩"

}

FUN_CORE()
{
	echo "`find $HOME/ -name "core*" | xargs ls -lart`"

}

FUN_XZ()
{
	LOCAL_SQL_6="select count(*) from ol_operrulepermit  a where a.status='1' and a.operno in (select operno from ol_operrole t where t.adddate='20130331' and t.sysno='99200000000'and t.rolestatus='1');"
	LOCAL_SQL_7="select count(*) from ol_operrole t where t.adddate='20130331' and t.sysno='99200000000'and t.rolestatus='1';"
        NE=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_6"`;
        NR=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_7"`;
	echo "������Ա����      [$NR]"
	echo "������ӦȨ������  [$NE]"
}

FUN_TJ()
{
	LOCAL_SQL_8="SELECT COUNT(*) FROM OL_OPERSIGN WHERE SIGNSTATUS='1' AND SYSNO='99200000000';"
	LOCAL_SQL_9="SELECT COUNT(*) FROM OL_OPERSIGN WHERE SIGNSTATUS='1' AND SYSNO='99340000000';"
	LOCAL_SQL_10="SELECT COUNT(*) FROM PBX_BOX_MGMT WHERE BOX_NO='01' AND stat='1' and INST_NO not like '%Z';"
	LOCAL_SQL_11="SELECT COUNT(*) FROM PBX_BOX_MGMT WHERE stat='1' and INST_NO not like '%Z';"

	LOCAL_SQL_18="SELECT COUNT(*) FROM OL_OPERSIGN WHERE SIGNSTATUS='1' AND SYSNO='99700010000';"

	GSGY=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_8"`; 
	GDGY=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_9"`;
	WXA=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_11"`;
	WXZ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_10"`;

	LJJZGY=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_18"`;

	echo "��˾��Աǩ������ [$GSGY]"
	echo "������Աǩ������ [$GDGY]"
	echo "����β���������� [$WXZ]"   
	echo "��Աβ���������� [$WXA]"


	echo "�߼����й�Աǩ������ [$LJJZGY]"
}


FUN_SC()
{
	LOCAL_SQL_12="select t.RECESYSNO || '  ', t.receprodcode||'  ', y.tran_name, round(avg(t.protime),2) AS "��������ʱ��" ,round(avg(t.backtime), 2),count(*) from OL_TRANSDETAIL_$DAYNUM t , ch_trans_cfg y where t.transdate='$DTY' and t.RECESYSNO=y.sys_id and t.receprodcode=y.tran_code  group by t.RECESYSNO,t.receprodcode,y.tran_name order by ��������ʱ�� ;"

echo "ִ�����[$LOCAL_SQL_12]"
	HSTJ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_12"`;	
	echo "ϵͳ����   ��̨������     ��������		               ��������ʱ��           ��̨����ʱ��     ����"
	echo "$HSTJ" 
}
FUN_CT()
{
	LOCAL_SQL_14="select to_char ((sysdate-1),'YYYYmmdd') from dual;"
	DDTY=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_14"`;
	LOCAL_SQL_13="select t.orderid||'     ',t.describe||'  ',decode(t.status,'0','��ʼ','1','�ɹ�','2','ʧ��')  from dc_trands_log t where t.tran_date='$DDTY' order by t.orderid;"
	echo "ִ�����Ϊ[ $LOCAL_SQL_13]"
	echo "--------       ----------------         ----------------"
	echo "˳��           ������Ϣ                        ״̬"
	echo "--------       ----------------         ----------------"
	DAY_CT=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_13"`;
	echo "--------       ----------------         ----------------"
	echo "$DAY_CT"
}


FUN_BLO()
{
LOCAL_SQL_15="SELECT UPPER(F.TABLESPACE_NAME) \"��ռ���\",D.TOT_GROOTTE_MB \"��ռ��С(M)\",D.TOT_GROOTTE_MB - F.TOTAL_BYTES \"��ʹ�ÿռ�(M)\",TO_CHAR(ROUND((D.TOT_GROOTTE_MB - F.TOTAL_BYTES) / D.TOT_GROOTTE_MB * 100, 2), '990.99') \"ʹ�ñ�\",F.TOTAL_BYTES \"���пռ�(M)\",F.MAX_BYTES \"����(M)\"  FROM (SELECT TABLESPACE_NAME,ROUND(SUM(BYTES) / (1024 * 1024), 2) TOTAL_BYTES,ROUND(MAX(BYTES) / (1024 * 1024), 2) MAX_BYTES  FROM SYS.DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) F,(SELECT DD.TABLESPACE_NAME,ROUND(SUM(DD.BYTES) / (1024 * 1024), 2) TOT_GROOTTE_MB  FROM SYS.DBA_DATA_FILES DD GROUP BY DD.TABLESPACE_NAME) D WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME ORDER BY 4 DESC;"
echo "ִ����䡾$LOCAL_SQL_15��"
echo "--------                      ------------   ------------ ------   ----------    --------"
echo "��ռ���                      ��ռ��С(M)  ��ʹ�ÿռ�(M)ʹ�ñ�%  ���пռ�(M)   ����(M)" 
echo "--------                      ------------   ------------ ------   ----------    --------"

BLO=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_15"`;
echo "$BLO"
echo "--------                      ------------   ------------ ------   ----------    --------"

}

FUN_DF()
{
	echo "----------    ---------      ---- -----    ----- ------ ------ ---"
	df -g
	echo "----------    ---------      ---- -----    ----- ------ ------ ---"
}
FUN_TXYCTJ()
{
CX0=`CONNECT_SQL "$LOCAL_DB"  "select '&&   '||t.recesysno,count(*),'   '||f.sys_name from ol_transdetail_$DAYNUM t ,ch_sys_cfg f where t.cmpretcode ='09209990' and substr(LOCALDATETIME,1,8) ='$DTY' and f.sys_id=t.recesysno group by t.recesysno,f.sys_name;"`;
CX_0=`CONNECT_SQL "$LOCAL_DB"  "select '##   '||t.recesysno,count(*),'   '||f.sys_name from ol_transdetail_$DAYNUM t ,ch_sys_cfg f where t.cmpretcode ='09209997' and substr(LOCALDATETIME,1,8) ='$DTY' and f.sys_id=t.recesysno  group by t.recesysno,f.sys_name;"`;



CX00=`CONNECT_SQL "$REMOTE_DB"  "select '&&   '||t.recesysno,count(*),'   '||f.sys_name from ol_transdetail_$DAYNUM t ,ch_sys_cfg f where t.cmpretcode ='09209990' and substr(LOCALDATETIME,1,8) ='$DTY' and f.sys_id=t.recesysno  group by t.recesysno,f.sys_name;"`;
CX_00=`CONNECT_SQL "$REMOTE_DB"  "select '##   '||t.recesysno,count(*),'   '||f.sys_name from ol_transdetail_$DAYNUM t ,ch_sys_cfg f where t.cmpretcode ='09209997' and substr(LOCALDATETIME,1,8) ='$DTY' and f.sys_id=t.recesysno  group by t.recesysno,f.sys_name;"`;


echo "$CX0" >  $HOME/log/jysc_LOCAL_DB.txt
echo "$CX_0" >> $HOME/log/jysc_LOCAL_DB.txt


echo "$CX00" >  $HOME/log/jysc_REMOTE_DB.txt
echo "$CX_00" >>  $HOME/log/jysc_REMOTE_DB.txt

echo "" > $HOME/log/jysc_tmp1.txt
echo "" > $HOME/log/jysc_tmp2.txt
while read line 
do
#echo "-------------------------------------$line"
flag_1=`echo $line | awk '{print $1}'`
if [ "$flag_1" != "&&" ]; 
then
#echo "&&&&&&&&&&&&&&&&&&&&&&&&"
	continue
fi
SYSNO_1=`echo $line | awk '{print $2}'`
COUNT_1=`echo $line | awk '{print $3}'`
SYSNO_NAME=`echo $line | awk '{print $4}'`
COUNT_2=`cat $HOME/log/jysc_LOCAL_DB.txt| grep "##" | grep $SYSNO_1 | awk '{print $3}'`
if [ "A$COUNT_2" == "A" ]; 
then
	COUNT_2=0
fi 
COUNTS_ALL=`CONNECT_SQL "$LOCAL_DB"  "select count(*) from ol_transdetail_$DAYNUM t   where  substr(LOCALDATETIME,1,8) ='$DTY' and t.recesysno = '$SYSNO_1';"`;

printf '&    %-15s%-20s' $SYSNO_1 $SYSNO_NAME>> $HOME/log/jysc_tmp1.txt
printf '%10s' $COUNT_1 >> $HOME/log/jysc_tmp1.txt
printf '%15s' $COUNT_2 >> $HOME/log/jysc_tmp1.txt 
printf '%15s\n' $COUNTS_ALL  >> $HOME/log/jysc_tmp1.txt 
done < $HOME/log/jysc_LOCAL_DB.txt

while read line 
do
#echo "-------------------------------------$line"
flag_1=`echo $line | awk '{print $1}'`
if [ "$flag_1" != "##" ]; 
then
#echo "#########################"
	continue
fi
SYSNO_1=`echo $line | awk '{print $2}'`
SYSNO_NAME=`echo $line | awk '{print $4}'`
flag_2=`cat $HOME/log/jysc_tmp1.txt | grep $SYSNO_1 | wc -l | awk '{print $1}'`
if [ "$flag_2" != "0" ]
then
#	echo "**************************$SYSNO_1"
	continue
fi
COUNT_2=`echo $line | awk '{print $3}'`
COUNT_1=`cat $HOME/log/jysc_LOCAL_DB.txt| grep "&&" | grep $SYSNO_1 | awk '{print $3}'`
if [ "A$COUNT_1" == "A" ]; 
then
	COUNT_1=0
fi 
COUNTS_ALL=`CONNECT_SQL "$LOCAL_DB"  "select count(*) from ol_transdetail_$DAYNUM t  where  substr(LOCALDATETIME,1,8) ='$DTY' and t.recesysno = '$SYSNO_1';"`;

printf '#    %-15s%-20s' $SYSNO_1 $SYSNO_NAME>> $HOME/log/jysc_tmp1.txt
printf '%10s' $COUNT_1 >> $HOME/log/jysc_tmp1.txt
printf '%15s' $COUNT_2 >> $HOME/log/jysc_tmp1.txt 
printf '%15s\n' $COUNTS_ALL  >> $HOME/log/jysc_tmp1.txt 
done < $HOME/log/jysc_LOCAL_DB.txt

printf '%16s\n' $LOCAL_DB
printf '%-35s' "     ҵ��ϵͳ" 
printf '%15s' ��ʱ���ױ���
printf '%15s' ͨѶ����
printf '%15s\n' �ܽ��ױ���
cat $HOME/log/jysc_tmp1.txt

###################################################################################################

while read line 
do
#echo "-------------------------------------$line"
flag_1=`echo $line | awk '{print $1}'`
if [ "$flag_1" != "&&" ]; 
then
#echo "&&&&&&&&&&&&&&&&&&&&&&&&"
	continue
fi
SYSNO_1=`echo $line | awk '{print $2}'`
SYSNO_NAME=`echo $line | awk '{print $4}'`
COUNT_1=`echo $line | awk '{print $3}'`
COUNT_2=`cat $HOME/log/jysc_REMOTE_DB.txt| grep "##" | grep $SYSNO_1 | awk '{print $3}'`
if [ "A$COUNT_2" == "A" ]; 
then
	COUNT_2=0
fi 
COUNTS_ALL=`CONNECT_SQL "$REMOTE_DB"  "select count(*) from ol_transdetail_$DAYNUM t  where  substr(LOCALDATETIME,1,8) ='$DTY' and t.recesysno = '$SYSNO_1';"`;

printf '&    %-15s%-20s' $SYSNO_1 $SYSNO_NAME>> $HOME/log/jysc_tmp2.txt
printf '%10s' $COUNT_1 >> $HOME/log/jysc_tmp2.txt
printf '%15s' $COUNT_2 >> $HOME/log/jysc_tmp2.txt 
printf '%15s\n' $COUNTS_ALL  >> $HOME/log/jysc_tmp2.txt 
done < $HOME/log/jysc_REMOTE_DB.txt

while read line 
do
#echo "-------------------------------------$line"
flag_1=`echo $line | awk '{print $1}'`
if [ "$flag_1" != "##" ]; 
then
#echo "#########################"
	continue
fi
SYSNO_1=`echo $line | awk '{print $2}'`
SYSNO_NAME=`echo $line | awk '{print $4}'`
flag_2=`cat $HOME/log/jysc_tmp2.txt | grep $SYSNO_1 | wc -l | awk '{print $1}'`
if [ "$flag_2" != "0" ]
then
#	echo "**************************$SYSNO_1"
	continue
fi
COUNT_2=`echo $line | awk '{print $3}'`
COUNT_1=`cat $HOME/log/jysc_LOCAL_DB.txt| grep "&&" | grep $SYSNO_1 | awk '{print $3}'`
if [ "A$COUNT_1" == "A" ]; 
then
	COUNT_1=0
fi 
COUNTS_ALL=`CONNECT_SQL "$REMOTE_DB"  "select count(*) from ol_transdetail_$DAYNUM t  where  substr(LOCALDATETIME,1,8) ='$DTY' and t.recesysno = '$SYSNO_1';"`;

printf '#    %-15s%-20s' $SYSNO_1 $SYSNO_NAME >> $HOME/log/jysc_tmp2.txt
printf '%10s' $COUNT_1 >> $HOME/log/jysc_tmp2.txt
printf '%15s' $COUNT_2 >> $HOME/log/jysc_tmp2.txt 
printf '%15s\n' $COUNTS_ALL  >> $HOME/log/jysc_tmp2.txt 
done < $HOME/log/jysc_REMOTE_DB.txt


printf '%16s\n' $REMOTE_DB
printf '%-35s' "     ҵ��ϵͳ" 
printf '%15s' ��ʱ���ױ���
printf '%15s' ͨѶ����
printf '%15s\n' �ܽ��ױ���
cat $HOME/log/jysc_tmp2.txt
}
CONNECT_SQL()
{
	sqlplus -S $1 <<EOF
	set echo off
	set head off
	set heading off
	set space 0
	set termout off
	set headsep off
	set newpage none
	set linesize 150
	set pagesize 2200
	set lines 800
	set sqlblanklines OFF
	set trimout on
	set trimspool ON
	set termout off
	set feedback off
	$2
	quit;
EOF
}
while true
do
#clear
echo "\n----------------------------------�ռ�鴦��-----------------------------------\n";
echo "   1. ������                                 11. ��Աǩ��/β������ͳ��         ";
echo "   2. Tux���м��                              12. �������������̨����ʱ��ͳ��  ";
echo "   3. Tux������                              13. ����ִ�����                  ";
echo "   4. ���������                               14. ��ռ�ʹ�����                ";
echo "   5. CORE���                                 15. �ļ�ϵͳ���                  ";
echo "   6. SALT���                                 16. ͨѶ�쳣ͳ��                  ";
echo "   7. ��ʱ���                                                                   ";
echo "   8. ��ˮ���ٲ�ѯ                                                               ";
echo "   9. ������Ա����                                                               ";
echo "  10. ��Ա�뽻��Ȩ������                                                         ";
echo "\n-------------------------------------------------------------------------------";
echo "��ѡ��[1-15/Q]��\c"; 
read ANS
echo "\n"
if [ "NULL$ANS" = "NULL" ]
then
continue
fi
	case $ANS in
	1) FUN_QSRQ;
		;;
	2) FUN_PSR;
		;;
	3) FUN_PSC; 
		;;
	4) FUN_PQ;
		;;
	5) FUN_CORE;
		;;
	6) echo "gws -i TuxAll"| wsadmin -r | head -n 16
		;;
  7) FUN_HS;  
  	;;
  8) FUN_LS;
  	;;
  9) FUN_XZ;
	;;
  10) FUN_QX;
  	;;
  11) FUN_TJ;
    ;;
  12) FUN_SC;
  	;;
  13) FUN_CT;	
	;;
  14) FUN_BLO;	
	;;
  15) FUN_DF;	
	;;
	16) FUN_TXYCTJ;	
	;;
	*) echo "���˳���"
		exit 1
		;;
	esac
	#sleep 5;
done
