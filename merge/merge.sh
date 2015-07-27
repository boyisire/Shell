#!/bin/bash
. ./ShellScript.lib

#----------------------------------------Parameters Config Info----------------------#
#Դ���ݿ���Ϣ
FromUser=chmap
FromPass=chmap
FromLink=arptdbs
#Ŀ�����ݿ���Ϣ
ToUser=chmap
ToPass=chmap
ToLink=arptdbs
#DBLINK��
DB_LINK_NAME="DBLINK_CHMAP"
#���ݿ������־ <0:�û���.����  1:����@DBLINK��>
DB_UNION_FLAG=0
#ͬ�����б�
#TabList="OL_CHANNALINFO,OL_TERMINIAL,OL_DEPTINFO"
TabList="ol_terminial"

#----------------------------------------Main Program----------------------#
for Tab in `echo $TabList|sed 's/\,/ /g'`
do
#���ݿ����Ӵ�
DB_Info="${ToUser}/${ToPass}@${ToLink}"
echo "------------------------TableName=${Tab}------------------------"
#�����ֶ��б�,�����������ѯ����
SQL_Primary="SELECT COLUMN_NAME FROM USER_CONSTRAINTS C, USER_CONS_COLUMNS COL WHERE C.CONSTRAINT_NAME = COL.CONSTRAINT_NAME AND C.CONSTRAINT_TYPE = 'P' AND C.TABLE_NAME = UPPER('${Tab}');"
TabPriList=`Fun_DB "${SQL_Primary}"`
STR_WHERE=""
for a in $TabPriList
do
	STR_WHERE="${STR_WHERE} S.$a=O.$a AND"
done
STR_WHERE=`echo $STR_WHERE|sed 's/AND$//g'`

#�����ֶ��б�
SQL_InsertList="SELECT COLUMN_NAME FROM USER_TAB_COLUMNS WHERE TABLE_NAME = UPPER('${Tab}');"
TabInsertList=`Fun_DB "${SQL_InsertList}"`
STR_INSERT=""
for a in $TabInsertList
do
	STR_INSERT="${STR_INSERT}S.$a,"
done
STR_INSERT=`echo $STR_INSERT|sed 's/,$//g'`

#�����ֶ��б�
SQL_UpdateList="`echo $SQL_InsertList|sed 's/;/ MINUS /g'` $SQL_Primary"
TabUpdateList=`Fun_DB "${SQL_UpdateList}"`
STR_UPDATE=""
for a in $TabUpdateList
do
	STR_UPDATE="${STR_UPDATE}O.$a=S.$a,"
done
STR_UPDATE=`echo $STR_UPDATE|sed 's/,$//g'`

if [ $DB_UNION_FLAG -eq 0 ]
then
	TabObject="${ToUser}.${Tab}"
	TabSource="${FromUser}.${Tab}"
else
	TabObject="${ToUser}.${Tab}"
	TabSource="(SELECT * FROM ${Tab}@${DB_LINK_NAME})"
fi

SQL_Main="
MERGE INTO ${TabObject} O
USING��${TabSource} S
ON ($STR_WHERE)
WHEN MATCHED THEN
UPDATE
SET ${STR_UPDATE}
WHEN NOT MATCHED THEN
INSERT
VALUES($STR_INSERT);
"
echo "$SQL_Main"

done
