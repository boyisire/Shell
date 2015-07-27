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
LOCAL_SQL_2="select '收到日切时间[' || t.recv_date_time || ']', '	日切开始时间[' || t.change_date_time || ']', '	更改前日切日期[' || t.before_acc_date || ']', '	更改后日切日期[' || t.acc_date || ']' from Ol_Daychange t WHERE t.recv_date_time>(select to_char ((sysdate-1),'YYYYmmdd')||'000000' from dual);"
LOCAL_SQL_16="select count(*) from Ol_Daychange t WHERE t.recv_date_time>(select to_char ((sysdate-1),'YYYYmmdd')||'000000' from dual);"

#---------------------------------------------------------------------------------------------------------
lsh()
{
DATE="$ZQ"
TIME="$TQ"
LSH="$SEQ"

echo "开始查找 [$ZQ] [$TQ] [$SEQ] [$PID]"

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
#echo "当前行为$line"
                #取当前行的修改时间

                CURTIME=`echo $line | awk -F "\." '{print $NF}'`
                FILENAME=`echo $line | awk '{print $9}'`
#echo "[CURTIME=$CURTIME]"
#echo "[TIME=$TIME]"
                if [ "$CURTIME" == "debug" ]
                then
#echo "在文件[$FILENAME]中查找结果即可"
                        break

                else
                        if [[ "$CURTIME" <  "$TIME" ]]
                        then
#echo "小于"
                                continue
                        else
#echo "[$CURTIME]>[$TIME]"
#echo "大于 $FILENAME"
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
                echo "在文件[    $FILENAME     ]中查找结果即可"
                echo "已经找到，退出查找"
         #       exit
        fi
done
grep $LSH $HOME/log/XML*

result=$?

        if [ $result -eq 0 ]
        then
                echo "已经找到，退出查找"
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
		 echo "#####注意检查有没有收到日切通知，相应的日期对不对#####";
		 echo "渠道清算日期：$QSRQ";
		 if [ "$QSTZCT" -eq "0" ]
		 then 
		 	echo "警告：渠道没有收到日切通知，请检查！"
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
		 echo "please input seqno：\c"
		 read SEQ
		 echo "please input date[默认$DTY]:\c"
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
		 LOCAL_SQL_3="select '交易日期[' || t.transdate || ']', ' 交易时间[' || substr(LOCALDATETIME,9,6) ||  ']', ' 交易机构[' || t.transdept || ']', ' 产品代码[' || t.sendprodcode || ']',  ' 日志IP[' || t.logip || ']',' PID[' || t.pid || ']'
from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY' and rownum=1;"
		 echo "日期[$DTY]的流水表是[OL_TRANSDETAIL_$NEWDAYNUM],注意流水的发生日期!"

		 LSCX=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_3"`;
		 
if [ "A$LSCX" == "A" ]
then
		 LSCX=`CONNECT_SQL "$REMOTE_DB" "$LOCAL_SQL_3"`;
		 CURRENT_DB=$REMOTE_DB
fi
if [ "A$LSCX" == "A" ]
then
		 echo "未找到流水号[$SEQ]对应记录"
		 return
fi

		 echo "$LSCX";
		 
     echo "数据库查询语句为 CONNECT_SQL \"$CURRENT_DB\" \"select transdate,substr(LOCALDATETIME,9,6),logip,pid  from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY'  and rownum=1 order by LOCALDATETIME desc;\""

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
				echo "请登录[$IP]查询指定进程号[$PID]流水[$SEQ]"
				return
		 fi
#     TQ=`CONNECT_SQL "$CURRENT_DB" "select substr(LOCALDATETIME,9,6) from OL_TRANSDETAIL_$NEWDAYNUM t where t.sendtranid = '$SEQ' and t.transdate = '$NEWDTY'  and rownum=1 order by LOCALDATETIME desc ;"`


		 lsh;
}

FUN_QX()
{
		 echo "请输入柜员号：\c"
     read GUIYUAN
     LOCAL_SQL_4="select '柜员['||t.operno||']', ' 角色['||t.rolenos||']',' 创建日期['||t.adddate||']',' 修改日期['||t.chdate||']' from ol_operrole t where t.operno = '$GUIYUAN' and t.sysno = '99200000000';";
     GYQX=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_4"`;
     echo "$GYQX"
     echo "请输入交易码：\c"
     read JIAYM
     LOCAL_SQL_5="select t.ruleno from ol_ruletrans t where t.prodcode='$JIAYM' and sysno='99200000000';";
     JYMJ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_5"`;
     echo "说明：99后面的三位是角色代码，未位1表示交易权限，2表示授权权限"
     echo "$JYMJ"
}

FUN_HS()
{
		 echo "ECIF     平均耗时："`grep 耗时 $HOME/log/*.ECIF | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"（毫秒）"
		 echo "ZJQS     平均耗时："`grep 耗时 $HOME/log/*.ZJQS | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"（毫秒）"
		 echo "TOKEN    平均耗时："`grep 耗时 $HOME/log/*.TOKEN | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"（毫秒）"
		 echo "ZHIWEN   平均耗时："`grep 耗时 $HOME/log/*.ZHIWEN | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"（毫秒）"
		 echo "185   平均耗时："`grep 耗时 $HOME/log/*.185 | awk -F "[" '{print $3}' | awk -F "]" '{print $1}' | tail -n 100 | awk '{sum+=$0}END{print sum/NR}'`"（毫秒）"

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
	echo "新增柜员数量      [$NR]"
	echo "新增对应权限数量  [$NE]"
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

	echo "公司柜员签到数量 [$GSGY]"
	echo "个贷柜员签到数量 [$GDGY]"
	echo "机构尾箱领用数量 [$WXZ]"   
	echo "柜员尾箱领用数量 [$WXA]"


	echo "逻辑集中柜员签到数量 [$LJJZGY]"
}


FUN_SC()
{
	LOCAL_SQL_12="select t.RECESYSNO || '  ', t.receprodcode||'  ', y.tran_name, round(avg(t.protime),2) AS "渠道处理时长" ,round(avg(t.backtime), 2),count(*) from OL_TRANSDETAIL_$DAYNUM t , ch_trans_cfg y where t.transdate='$DTY' and t.RECESYSNO=y.sys_id and t.receprodcode=y.tran_code  group by t.RECESYSNO,t.receprodcode,y.tran_name order by 渠道处理时长 ;"

echo "执行语句[$LOCAL_SQL_12]"
	HSTJ=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_12"`;	
	echo "系统代码   后台交易码     交易名称		               渠道处理时长           后台处理时长     笔数"
	echo "$HSTJ" 
}
FUN_CT()
{
	LOCAL_SQL_14="select to_char ((sysdate-1),'YYYYmmdd') from dual;"
	DDTY=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_14"`;
	LOCAL_SQL_13="select t.orderid||'     ',t.describe||'  ',decode(t.status,'0','初始','1','成功','2','失败')  from dc_trands_log t where t.tran_date='$DDTY' order by t.orderid;"
	echo "执行语句为[ $LOCAL_SQL_13]"
	echo "--------       ----------------         ----------------"
	echo "顺序           操作信息                        状态"
	echo "--------       ----------------         ----------------"
	DAY_CT=`CONNECT_SQL "$LOCAL_DB" "$LOCAL_SQL_13"`;
	echo "--------       ----------------         ----------------"
	echo "$DAY_CT"
}


FUN_BLO()
{
LOCAL_SQL_15="SELECT UPPER(F.TABLESPACE_NAME) \"表空间名\",D.TOT_GROOTTE_MB \"表空间大小(M)\",D.TOT_GROOTTE_MB - F.TOTAL_BYTES \"已使用空间(M)\",TO_CHAR(ROUND((D.TOT_GROOTTE_MB - F.TOTAL_BYTES) / D.TOT_GROOTTE_MB * 100, 2), '990.99') \"使用比\",F.TOTAL_BYTES \"空闲空间(M)\",F.MAX_BYTES \"最大块(M)\"  FROM (SELECT TABLESPACE_NAME,ROUND(SUM(BYTES) / (1024 * 1024), 2) TOTAL_BYTES,ROUND(MAX(BYTES) / (1024 * 1024), 2) MAX_BYTES  FROM SYS.DBA_FREE_SPACE GROUP BY TABLESPACE_NAME) F,(SELECT DD.TABLESPACE_NAME,ROUND(SUM(DD.BYTES) / (1024 * 1024), 2) TOT_GROOTTE_MB  FROM SYS.DBA_DATA_FILES DD GROUP BY DD.TABLESPACE_NAME) D WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME ORDER BY 4 DESC;"
echo "执行语句【$LOCAL_SQL_15】"
echo "--------                      ------------   ------------ ------   ----------    --------"
echo "表空间名                      表空间大小(M)  已使用空间(M)使用比%  空闲空间(M)   最大块(M)" 
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
printf '%-35s' "     业务系统" 
printf '%15s' 超时交易笔数
printf '%15s' 通讯错误
printf '%15s\n' 总交易笔数
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
printf '%-35s' "     业务系统" 
printf '%15s' 超时交易笔数
printf '%15s' 通讯错误
printf '%15s\n' 总交易笔数
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
echo "\n----------------------------------日检查处理-----------------------------------\n";
echo "   1. 清算检查                                 11. 柜员签到/尾箱领用统计         ";
echo "   2. Tux队列检查                              12. 交易在渠道与后台处理时长统计  ";
echo "   3. Tux服务检查                              13. 日终执行情况                  ";
echo "   4. 连接数检查                               14. 表空间使用情况                ";
echo "   5. CORE检查                                 15. 文件系统检查                  ";
echo "   6. SALT检查                                 16. 通讯异常统计                  ";
echo "   7. 耗时检查                                                                   ";
echo "   8. 流水快速查询                                                               ";
echo "   9. 新增柜员数量                                                               ";
echo "  10. 柜员与交易权限问题                                                         ";
echo "\n-------------------------------------------------------------------------------";
echo "请选择[1-15/Q]：\c"; 
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
	*) echo "已退出！"
		exit 1
		;;
	esac
	#sleep 5;
done
